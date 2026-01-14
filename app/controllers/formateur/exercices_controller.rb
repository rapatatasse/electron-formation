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

  private

  def require_formateur
    unless current_user.formateur? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
