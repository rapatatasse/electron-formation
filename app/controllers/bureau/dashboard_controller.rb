class Bureau::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_bureau

  def index
    @projects_count = Project.count
    @tasks_count = Task.count
    @recent_projects = Project.order(created_at: :desc).limit(5)
  end

  private

  def require_bureau
    unless current_user.bureau? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
