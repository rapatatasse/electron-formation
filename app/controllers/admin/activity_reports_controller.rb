module Admin
  class ActivityReportsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin!

    def index
      @date = params[:date] ? Date.parse(params[:date]) : Time.current
      @service = UserActivityReportService.new(@date)
      @report = @service.generate_monthly_report
    end

    def user_report
      @user = User.find(params[:id])
      @date = params[:date] ? Date.parse(params[:date]) : Time.current
      @service = UserActivityReportService.new(@date)
      @report = @service.generate_user_report(@user)
    end

    def export
      @date = params[:date] ? Date.parse(params[:date]) : Time.current
      @service = UserActivityReportService.new(@date)
      
      respond_to do |format|
        format.csv do
          send_data @service.export_to_csv,
                    filename: "user_activity_#{@date.strftime('%Y_%m')}.csv",
                    type: 'text/csv; charset=utf-8'
        end
      end
    end

    private

    def ensure_admin!
      redirect_to root_path, alert: 'Accès non autorisé' unless current_user.admin?
    end
  end
end
