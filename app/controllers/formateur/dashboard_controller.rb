class Formateur::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_formateur

  def index
    @my_quizzes = Quiz.all.order(created_at: :desc).limit(5)
    
  end

  private

  def require_formateur
    unless current_user.formateur? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
