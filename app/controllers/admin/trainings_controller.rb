class Admin::TrainingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_training, only: [:show, :edit, :update, :destroy, :toggle_publish]

  def index
    @trainings = Training.ordered_by_priority.page(params[:page]).per(20)
  end

  def show
  end

  def new
    @training = Training.new
  end

  def create
    @training = Training.new(training_params)
    
    if @training.save
      redirect_to admin_trainings_path, notice: "Formation créée avec succès"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @training.update(training_params)
      redirect_to admin_trainings_path, notice: "Formation mise à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @training.destroy
    redirect_to admin_trainings_path, notice: "Formation supprimée"
  end
  
  def toggle_publish
    @training.update(published: !@training.published)
    redirect_to admin_trainings_path, notice: "Statut de publication mis à jour"
  end
  
  def import
  end
  
  def process_import
    unless params[:file].present?
      redirect_to import_admin_trainings_path, alert: "Veuillez sélectionner un fichier Excel (.xlsx)"
      return
    end
    
    file = params[:file]
    file_ext = File.extname(file.original_filename).downcase
    
    unless file_ext == '.xlsx'
      redirect_to import_admin_trainings_path, alert: "Seuls les fichiers Excel (.xlsx) sont acceptés"
      return
    end
    
    result = Training.import_from_excel(file.path)
    
    if result[:errors].any?
      flash[:alert] = "#{result[:count]} formations importées avec #{result[:errors].count} erreurs : #{result[:errors].first(3).join('; ')}"
    else
      flash[:notice] = "#{result[:count]} formations importées avec succès"
    end
    
    redirect_to admin_trainings_path
  end
  
  def export
    excel_data = Training.export_to_excel
    send_data excel_data, 
              filename: "formations_#{Date.today}.xlsx", 
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end

  private

  def set_training
    @training = Training.find(params[:id])
  end

  def training_params
    params.require(:training).permit(
      :title, :price_intra_ht, :price_inter_ht, :training_type, :image_url,
      :duration, :description, :objective, :program, :target_audience,
      :teaching_methods, :prerequisites, :priority, :evaluation_method, :published
    )
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
