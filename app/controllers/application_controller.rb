class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  
  before_action :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :locale])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone, :locale])
  end
end
