module ActivityTrackable
  extend ActiveSupport::Concern

  def log_activity(action_type:, resource: nil, metadata: {}, request: nil)
    UserActivityLog.log_activity(
      user: self,
      action_type: action_type,
      resource: resource,
      metadata: metadata,
      request: request
    )
  end

  def monthly_activity_stats(date = Time.current)
    UserActivityLog.monthly_stats(self, date)
  end

  def recent_activities(limit = 50)
    UserActivityLog.for_user(self).recent.limit(limit)
  end

  def activity_summary(start_date, end_date)
    logs = UserActivityLog.for_user(self)
                          .where(performed_at: start_date..end_date)
    
    {
      period: "#{start_date.to_date} - #{end_date.to_date}",
      total_activities: logs.count,
      by_action: logs.group(:action_type).count,
      by_day: logs.group("DATE(performed_at)").count,
      active_days: logs.pluck(:performed_at).map(&:to_date).uniq.count
    }
  end
end
