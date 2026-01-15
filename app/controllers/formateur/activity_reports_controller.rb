module Formateur
  class ActivityReportsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_formateur_or_admin!

    def index
      @date = params[:date] ? Date.parse(params[:date]) : Time.current
      @service = UserActivityReportService.new(@date)
      
      if current_user.formateur?
        @users = User.where(role: :apprenant)
        @report = limited_report_for_formateur
      else
        @report = @service.generate_monthly_report
      end
    end

    def user_report
      @user = User.find(params[:id])
      
      if current_user.formateur? && !@user.apprenant?
        redirect_to formateur_activity_reports_path, alert: 'Accès non autorisé'
        return
      end
      
      @date = params[:date] ? Date.parse(params[:date]) : Time.current
      @service = UserActivityReportService.new(@date)
      @report = @service.generate_user_report(@user)
    end

    private

    def ensure_formateur_or_admin!
      unless current_user.formateur? || current_user.admin?
        redirect_to root_path, alert: 'Accès non autorisé'
      end
    end

    def limited_report_for_formateur
      apprenants = User.where(role: :apprenant)
      
      {
        period: "#{@date.beginning_of_month.strftime('%B %Y')}",
        generated_at: Time.current,
        total_users: apprenants.count,
        active_users: active_apprenants_count,
        users_details: apprenants_activity_details,
        top_active_users: top_active_apprenants(10)
      }
    end

    def active_apprenants_count
      UserActivityLog.joins(:user)
                     .where(users: { role: :apprenant })
                     .where(performed_at: @date.beginning_of_month..@date.end_of_month)
                     .distinct.count(:user_id)
    end

    def apprenants_activity_details
      User.where(role: :apprenant).includes(:user_activity_logs).map do |user|
        stats = user.monthly_activity_stats(@date)
        {
          user_id: user.id,
          name: user.full_name,
          email: user.email,
          session: user.session,
          stats: stats
        }
      end
    end

    def top_active_apprenants(limit = 10)
      UserActivityLog.joins(:user)
                     .where(users: { role: :apprenant })
                     .where(performed_at: @date.beginning_of_month..@date.end_of_month)
                     .group(:user_id)
                     .count
                     .sort_by { |_, count| -count }
                     .first(limit)
                     .map do |user_id, count|
        user = User.find(user_id)
        {
          user_id: user.id,
          name: user.full_name,
          email: user.email,
          session: user.session,
          activity_count: count
        }
      end
    end
  end
end
