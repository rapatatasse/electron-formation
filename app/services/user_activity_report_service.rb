class UserActivityReportService
  def initialize(date = Time.current)
    @date = date
    @start_date = date.beginning_of_month
    @end_date = date.end_of_month
  end

  def generate_monthly_report
    {
      period: "#{@start_date.strftime('%B %Y')}",
      generated_at: Time.current,
      total_users: User.count,
      active_users: active_users_count,
      users_details: users_activity_details,
      global_stats: global_activity_stats,
      top_active_users: top_active_users(10),
      activity_by_day: activity_by_day,
      activity_by_action: activity_by_action
    }
  end

  def generate_user_report(user)
    logs = UserActivityLog.for_user(user).for_month(@date)
    
    {
      user: {
        id: user.id,
        name: user.full_name,
        email: user.email,
        role: user.role
      },
      period: "#{@start_date.strftime('%B %Y')}",
      stats: user.monthly_activity_stats(@date),
      daily_breakdown: daily_activity_breakdown(user),
      quiz_performance: quiz_performance_summary(user),
      login_patterns: login_patterns(user)
    }
  end

  def export_to_csv
    require 'csv'
    
    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << ['User ID', 'Name', 'Email', 'Role', 'Total Activities', 'Logins', 
              'Quizzes Started', 'Quizzes Completed', 'Active Days', 'Last Activity']
      
      User.find_each do |user|
        stats = user.monthly_activity_stats(@date)
        csv << [
          user.id,
          user.full_name,
          user.email,
          user.role,
          stats[:total_activities],
          stats[:logins],
          stats[:quizzes_started],
          stats[:quizzes_completed],
          stats[:active_days],
          stats[:last_activity]&.strftime('%Y-%m-%d %H:%M')
        ]
      end
    end
  end

  private

  def active_users_count
    UserActivityLog.where(performed_at: @start_date..@end_date)
                   .distinct.count(:user_id)
  end

  def users_activity_details
    User.includes(:user_activity_logs).map do |user|
      stats = user.monthly_activity_stats(@date)
      {
        user_id: user.id,
        name: user.full_name,
        email: user.email,
        role: user.role,
        stats: stats
      }
    end
  end

  def global_activity_stats
    logs = UserActivityLog.where(performed_at: @start_date..@end_date)
    
    {
      total_activities: logs.count,
      by_action_type: logs.group(:action_type).count,
      unique_active_users: logs.distinct.count(:user_id),
      avg_activities_per_user: logs.count.to_f / active_users_count.to_f,
      peak_activity_day: logs.group("DATE(performed_at)").count.max_by { |_, v| v }&.first
    }
  end

  def top_active_users(limit = 10)
    UserActivityLog.where(performed_at: @start_date..@end_date)
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
        activity_count: count
      }
    end
  end

  def activity_by_day
    UserActivityLog.where(performed_at: @start_date..@end_date)
                   .group("DATE(performed_at)")
                   .count
                   .sort
  end

  def activity_by_action
    UserActivityLog.where(performed_at: @start_date..@end_date)
                   .group(:action_type)
                   .count
  end

  def daily_activity_breakdown(user)
    UserActivityLog.for_user(user)
                   .where(performed_at: @start_date..@end_date)
                   .group("DATE(performed_at)")
                   .group(:action_type)
                   .count
  end

  def quiz_performance_summary(user)
    attempts = user.quiz_attempts.where(created_at: @start_date..@end_date)
    
    {
      total_attempts: attempts.count,
      completed: attempts.where.not(completed_at: nil).count,
      passed: attempts.where(passed: true).count,
      average_score: attempts.average(:score)&.round(2),
      total_time_spent: attempts.sum(:time_spent)
    }
  end

  def login_patterns(user)
    logins = UserActivityLog.for_user(user)
                            .by_action('login')
                            .where(performed_at: @start_date..@end_date)
    
    {
      total_logins: logins.count,
      by_day_of_week: logins.group("strftime('%w', performed_at)").count,
      by_hour: logins.group("strftime('%H', performed_at)").count,
      unique_ips: logins.distinct.pluck(:ip_address).compact.count
    }
  end
end
