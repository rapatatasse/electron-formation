class HomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to dashboard_path
    end
    @hide_nav = true
  end

  def dashboard
    # Utiliser le rôle principal pour la redirection
    case current_user.primary_role
    when 'admin'
      redirect_to admin_dashboard_path
    when 'formateur'
      redirect_to formateur_dashboard_path
    when 'bureau'
      redirect_to bureau_dashboard_path
    when 'apprenant'
      redirect_to apprenant_dashboard_path
    else
      redirect_to root_path
    end
  end
end
