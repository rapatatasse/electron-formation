class Formateur::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_formateur

  def index
    @my_quizzes = current_user.created_quizzes.order(created_at: :desc).limit(5)
    @total_quizzes = current_user.created_quizzes.count
    @total_attempts = QuizAttempt.joins(:quiz).where(quizzes: { creator_id: current_user.id }).count
  end

  private

  def require_formateur
    unless current_user.formateur? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
