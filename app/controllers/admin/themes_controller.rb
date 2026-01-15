class Admin::ThemesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_theme, only: [:edit, :update, :destroy]

  def index
    @themes = Theme.order(:name)
  end

  def new
    @theme = Theme.new
  end

  def create
    @theme = Theme.new(theme_params)
    
    if @theme.save
      redirect_to admin_themes_path, notice: "Thème créé avec succès"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @theme.update(theme_params)
      redirect_to admin_themes_path, notice: "Thème mis à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @theme.destroy
    redirect_to admin_themes_path, notice: "Thème supprimé"
  end

  private

  def set_theme
    @theme = Theme.find(params[:id])
  end

  def theme_params
    params.require(:theme).permit(:name, :description, :color)
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
