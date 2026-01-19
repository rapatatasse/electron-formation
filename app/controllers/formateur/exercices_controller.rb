class Formateur::ExercicesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_formateur

  def index
  end

  def dragdrop
    @hide_nav = true
  end

  def elingage
  end

  def daoe
    pdf_name = params[:pdf_name]
    pdf_path = Rails.root.join('app', 'assets', 'images', 'exercices', 'DAOE', "#{pdf_name}.pdf")
    
    if File.exist?(pdf_path)
      send_file pdf_path, type: 'application/pdf', disposition: 'inline'
    else
      render plain: "PDF non trouvé", status: :not_found
    end
  end

  private

  def require_formateur
    unless current_user.formateur? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
