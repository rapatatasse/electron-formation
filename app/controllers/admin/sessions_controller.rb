class Admin::SessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_session, only: [:destroy]

  def index
    @sessions = Session.includes(:users).ordered
    
    # Filtrer les utilisateurs (apprenants et formateurs uniquement)
    @users = User.where("'apprenant' = ANY(role) OR 'formateur' = ANY(role)")
                 .order(:last_name, :first_name)
    
    # Appliquer les filtres
    if params[:role].present? && params[:role] != 'all'
      @users = @users.where("? = ANY(role)", params[:role])
    end
    
    if params[:session_id].present? && params[:session_id] != 'all'
      @users = @users.joins(:user_sessions).where(user_sessions: { session_id: params[:session_id] })
    end
    
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where("LOWER(first_name) LIKE LOWER(?) OR LOWER(last_name) LIKE LOWER(?) OR LOWER(email) LIKE LOWER(?)", 
                           search_term, search_term, search_term)
    end
    
    @users = @users.includes(:sessions)
  end

  def create
    @session = Session.new(session_params)
    
    if @session.save
      redirect_to admin_sessions_path, notice: "Session '#{@session.name}' créée avec succès"
    else
      @sessions = Session.includes(:users).ordered
      @users = User.where("'apprenant' = ANY(role) OR 'formateur' = ANY(role)")
                   .order(:last_name, :first_name)
                   .includes(:sessions)
      render :index, status: :unprocessable_entity
    end
  end

  def assign
    user_id = params[:user_id]
    session_id = params[:session_id]
    
    user = User.find(user_id)
    session = Session.find(session_id)
    
    user_session = UserSession.find_or_create_by(user: user, session: session)
    
    if user_session.persisted?
      render json: { success: true, message: "Session '#{session.name}' assignée à #{user.full_name}" }
    else
      render json: { success: false, message: user_session.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def unassign
    user_id = params[:user_id]
    session_id = params[:session_id]
    
    user_session = UserSession.find_by(user_id: user_id, session_id: session_id)
    
    if user_session&.destroy
      user = User.find(user_id)
      session = Session.find(session_id)
      render json: { success: true, message: "Session '#{session.name}' retirée de #{user.full_name}" }
    else
      render json: { success: false, message: "Assignation non trouvée" }, status: :not_found
    end
  end

  def destroy
    name = @session.name
    @session.destroy
    redirect_to admin_sessions_path, notice: "Session '#{name}' supprimée"
  end

  private

  def set_session
    @session = Session.find(params[:id])
  end

  def session_params
    params.require(:session).permit(:name, :description, :active)
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
