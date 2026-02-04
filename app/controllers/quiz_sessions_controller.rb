class QuizSessionsController < ApplicationController
  def show
    @quiz_session = QuizSession.find_by!(token: params[:token])
    if !@quiz_session.active?
      render plain: 'Session inactive', status: :not_found
      return
    end

    @participant = current_quiz_participant

    if @participant
      @attempt = QuizAttempt.find_or_create_by!(
        quiz: @quiz_session.quiz,
        quiz_session: @quiz_session,
        quiz_participant: @participant
      ) do |attempt|
        attempt.status = 'in_progress'
        attempt.started_at = Time.current
      end

      if @attempt.completed?
        @results = @attempt
      else
        @current_question = @attempt.next_question
        if @current_question.nil?
          @attempt.complete!
          @results = @attempt
        end
      end
    end
  end

  def create_participant
    quiz_session = QuizSession.find_by!(token: params[:token])

    participant = quiz_session.quiz_participants.find_or_create_by!(
      identifier: normalized_identifier(params[:first_name], params[:last_name])
    ) do |p|
      p.first_name = params[:first_name]
      p.last_name = params[:last_name]
      p.email = params[:email].presence
    end

    session[participant_session_key(quiz_session)] = participant.id

    redirect_to quiz_session_path(quiz_session.token)
  end

  def submit_answer
    quiz_session = QuizSession.find_by!(token: params[:token])
    participant = current_quiz_participant(quiz_session)
    redirect_to quiz_session_path(quiz_session.token) and return unless participant

    attempt = QuizAttempt.find_by!(quiz_session: quiz_session, quiz_participant: participant)

    question = Question.find(params[:question_id])
    answer_ids = params[:answer_ids]&.reject(&:blank?) || []

    if answer_ids.empty?
      redirect_to quiz_session_path(quiz_session.token), alert: 'Veuillez sélectionner au moins une réponse'
      return
    end

    current_question = attempt.next_question
    if current_question.nil? || current_question.id != question.id
      redirect_to quiz_session_path(quiz_session.token), alert: 'Action non autorisée'
      return
    end

    attempt.add_answer(question, answer_ids)

    redirect_to quiz_session_path(quiz_session.token)
  end

  private

  def participant_session_key(quiz_session)
    "quiz_participant_#{quiz_session.id}"
  end

  def current_quiz_participant(quiz_session = nil)
    quiz_session ||= QuizSession.find_by(token: params[:token])
    return nil unless quiz_session

    participant_id = session[participant_session_key(quiz_session)]
    return nil unless participant_id

    quiz_session.quiz_participants.find_by(id: participant_id)
  end

  def normalized_identifier(first_name, last_name)
    "#{first_name} #{last_name}".to_s.downcase.strip.gsub(/\s+/, ' ')
  end
end
