class Admin::SessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  def index
    redirect_to admin_dashboard_path, alert: 'La fonctionnalité Sessions a été supprimée. Utilisez les QuizSessions.'
  end

  def create
    redirect_to admin_dashboard_path, alert: 'La fonctionnalité Sessions a été supprimée. Utilisez les QuizSessions.'
  end

  def assign
    head :not_found
  end

  def unassign
    head :not_found
  end

  def destroy
    head :not_found
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
