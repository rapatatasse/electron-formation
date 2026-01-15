module ActivityLogging
  extend ActiveSupport::Concern

  included do
    after_action :log_user_activity, if: :user_signed_in?
  end

  private

  def log_user_activity
    return unless should_log_activity?

    current_user.log_activity(
      action_type: determine_action_type,
      resource: determine_resource,
      metadata: activity_metadata,
      request: request
    )
  rescue => e
    Rails.logger.error "Failed to log activity: #{e.message}"
  end

  def should_log_activity?
    true
  end

  def determine_action_type
    case "#{controller_name}##{action_name}"
    when /sessions#create/
      'login'
    when /sessions#destroy/
      'logout'
    when /quiz_attempts#create/
      'quiz_started'
    when /quiz_attempts#update/
      params[:quiz_attempt][:completed_at].present? ? 'quiz_completed' : 'answer_submitted'
    when /quiz_attempts#destroy/
      'quiz_abandoned'
    when /certificates#create/
      'certificate_generated'
    when /users#update/, /registrations#update/
      'profile_updated'
    when /passwords#update/
      'password_changed'
    else
      "#{controller_name}_#{action_name}"
    end
  end

  def determine_resource
    instance_variable_get("@#{controller_name.singularize}") ||
    instance_variable_get("@quiz_attempt") ||
    instance_variable_get("@quiz")
  end

  def activity_metadata
    {
      controller: controller_name,
      action: action_name,
      params: filtered_params
    }
  end

  def filtered_params
    params.except(:controller, :action, :authenticity_token, :password, :password_confirmation)
          .to_unsafe_h
          .slice(*allowed_metadata_params)
  end

  def allowed_metadata_params
    [:id, :quiz_id, :question_id, :answer_ids, :score, :status]
  end
end
