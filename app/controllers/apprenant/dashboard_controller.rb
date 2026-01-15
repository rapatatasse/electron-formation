class Apprenant::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_apprenant

  def index
    # Récupérer uniquement les quiz assignés à l'apprenant
    @available_quizzes = current_user.assigned_quizzes.active.order(created_at: :desc)
    @my_attempts = current_user.quiz_attempts.recent.limit(5)
    @total_attempts = current_user.quiz_attempts.where(status: ['in_progress', 'completed']).count
    @passed_attempts = current_user.quiz_attempts.passed.count
    
    # Récupérer les assignations pour afficher les dates limites
    @assignments = current_user.quiz_attempts.assigned.includes(:quiz).index_by(&:quiz_id)
    
  end

  private

  def require_apprenant
    unless current_user.apprenant? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
