class UserActivityLog < ApplicationRecord
  belongs_to :user

  ACTION_TYPES = %w[
    login
    logout
    quiz_started
    quiz_completed
    quiz_abandoned
    answer_submitted
    certificate_generated
    profile_updated
    password_changed
  ].freeze

  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :performed_at, presence: true

  scope :for_user, ->(user) { where(user: user) }
  scope :for_month, ->(date = Time.current) { 
    where(performed_at: date.beginning_of_month..date.end_of_month) 
  }
  scope :by_action, ->(action_type) { where(action_type: action_type) }
  scope :recent, -> { order(performed_at: :desc) }

  def self.log_activity(user:, action_type:, resource: nil, metadata: {}, request: nil)
    create!(
      user: user,
      action_type: action_type,
      resource_type: resource&.class&.name,
      resource_id: resource&.id,
      metadata: metadata,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent,
      performed_at: Time.current
    )
  end

  def self.monthly_stats(user, date = Time.current)
    logs = for_user(user).for_month(date)
    last_login = for_user(user).by_action('login').order(performed_at: :desc).first
    
    {
      total_activities: logs.count,
      logins: logs.by_action('login').count,
      quizzes_started: logs.by_action('quiz_started').count,
      quizzes_completed: logs.by_action('quiz_completed').count,
      quizzes_abandoned: logs.by_action('quiz_abandoned').count,
      answers_submitted: logs.by_action('answer_submitted').count,
      certificates_generated: logs.by_action('certificate_generated').count,
      first_activity: logs.minimum(:performed_at),
      last_activity: logs.maximum(:performed_at),
      last_login: last_login&.performed_at,
      active_days: logs.pluck(:performed_at).map(&:to_date).uniq.count,
      by_action_type: logs.group(:action_type).count
    }
  end
end
