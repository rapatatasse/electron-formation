module Formateur
  class ActivityReportsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_formateur_or_admin!

    def index
      @date = params[:date] ? Date.parse(params[:date]) : Time.current
      @report = session_based_report
    end

    def user_report
      redirect_to formateur_activity_reports_path, alert: 'Rapport individuel indisponible (quiz publics)'
    end

    private

    def ensure_formateur_or_admin!
      unless current_user.formateur? || current_user.admin?
        redirect_to root_path, alert: 'Accès non autorisé'
      end
    end

    def session_based_report
      range = @date.beginning_of_month..@date.end_of_month

      quiz_sessions = QuizSession.where(created_at: range)
      quiz_sessions = quiz_sessions.where(created_by_id: current_user.id) if current_user.formateur?

      session_ids = quiz_sessions.pluck(:id)

      participants = QuizParticipant.where(quiz_session_id: session_ids)
      attempts = QuizAttempt.where(quiz_session_id: session_ids)
      completed_attempts = attempts.where(status: 'completed')

      top_participants = completed_attempts
        .joins(:quiz_participant)
        .group(:quiz_participant_id)
        .count
        .sort_by { |_, count| -count }
        .first(10)
        .map do |participant_id, count|
          p = participants.find { |pp| pp.id == participant_id } || QuizParticipant.find(participant_id)
          {
            participant_id: p.id,
            name: p.full_name,
            email: p.email,
            quizzes_completed: count
          }
        end

      participants_details = participants.includes(:quiz_attempts).map do |p|
        p_attempts = p.quiz_attempts.where(quiz_session_id: session_ids)
        completed = p_attempts.where(status: 'completed')
        last_activity = completed.maximum(:completed_at) || p_attempts.maximum(:started_at) || p_attempts.maximum(:created_at)

        {
          participant_id: p.id,
          name: p.full_name,
          email: p.email,
          stats: {
            quizzes_started: p_attempts.where.not(started_at: nil).count,
            quizzes_completed: completed.count,
            average_score: completed.average(:score)&.round(1),
            last_activity: last_activity
          }
        }
      end

      {
        period: "#{@date.beginning_of_month.strftime('%B %Y')}",
        generated_at: Time.current,
        total_sessions: quiz_sessions.count,
        total_participants: participants.count,
        total_attempts: attempts.count,
        completed_attempts: completed_attempts.count,
        participants_details: participants_details,
        top_participants: top_participants
      }
    end
  end
end
