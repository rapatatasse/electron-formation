class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_user, only: [:show, :edit, :update, :destroy, :reset_password]

  def index
    @users = User.order(created_at: :desc).page(params[:page]).per(20)
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.password = SecureRandom.hex(8) if @user.password.blank?
    
    if @user.save
      redirect_to admin_users_path, notice: "Utilisateur créé avec succès"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if user_params[:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if @user.update(user_params)
      redirect_to admin_users_path, notice: "Utilisateur mis à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: "Utilisateur supprimé"
  end

  def import
  end

  def process_import
    unless params[:file].present?
      redirect_to import_admin_users_path, alert: "Veuillez sélectionner un fichier CSV"
      return
    end

    file = params[:file]
    count = 0
    errors = []

    CSV.foreach(file.path, headers: true, col_sep: detect_separator(file.path)) do |row|
      begin
        user = User.find_or_initialize_by(email: row['email'])
        user.assign_attributes(
          first_name: row['first_name'] || row['prenom'],
          last_name: row['last_name'] || row['nom'],
          phone: row['phone'] || row['telephone'],
          session: row['session'],
          role: row['role'] || 'apprenant',
          locale: row['locale'] || 'fr'
        )
        
        if user.new_record?
          user.password = SecureRandom.hex(8)
          user.password_confirmation = user.password
        end
        
        if user.save
          count += 1
        else
          errors << "Ligne #{row.line_number}: #{user.errors.full_messages.join(', ')}"
        end
      rescue => e
        errors << "Ligne #{row.line_number}: #{e.message}"
      end
    end

    if errors.any?
      flash[:alert] = "#{count} utilisateurs importés avec #{errors.count} erreurs : #{errors.first(3).join('; ')}"
    else
      flash[:notice] = "#{count} utilisateurs importés avec succès"
    end
    
    redirect_to admin_users_path
  end

  def download_template
    send_data User.csv_template, filename: "template_import_apprenants.csv", type: 'text/csv; charset=utf-8'
  end
  
  def process_import
    result = User.import_from_csv(params[:file].path)
    
    if result[:errors].any?
      flash[:alert] = "#{result[:count]} utilisateurs importés avec #{result[:errors].count} erreurs"
    else
      flash[:notice] = "#{result[:count]} utilisateurs importés avec succès"
    end
    
    redirect_to admin_users_path
  end

  def reset_password
    new_password = params[:new_password]
    
    if new_password.blank?
      render json: { error: "Le mot de passe ne peut pas être vide" }, status: :unprocessable_entity
      return
    end
    
    if new_password.length < 6
      render json: { error: "Le mot de passe doit contenir au moins 6 caractères" }, status: :unprocessable_entity
      return
    end
    
    @user.password = new_password
    @user.password_confirmation = new_password
    
    if @user.save
      render json: { success: true, message: "Mot de passe réinitialisé avec succès pour #{@user.full_name}" }
    else
      render json: { error: @user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :role, :locale, :phone, :session, :password, :password_confirmation)
  end

  def detect_separator(file_path)
    first_line = File.open(file_path, &:readline)
    first_line.include?(';') ? ';' : ','
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
