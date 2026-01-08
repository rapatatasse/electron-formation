class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @users_count = User.count
    @courses_count = Course.count
    @quizzes_count = Quiz.count
    @recent_users = User.order(created_at: :desc).limit(5)
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
