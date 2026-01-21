class TrainingsController < ApplicationController
  def index
    @trainings = Training.published.ordered_by_priority
    
    # Recherche
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @trainings = @trainings.where(
        "title LIKE ? OR description LIKE ? OR training_type LIKE ?", 
        search_term, search_term, search_term
      )
    end
    
    # Filtres par type
    if params[:type].present?
      @trainings = @trainings.where("LOWER(training_type) LIKE ?", "%#{params[:type].downcase}%")
    end
  end

  def show
    @training = Training.published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to trainings_path, alert: "Formation non trouvée"
  end
  
  def show_catalog
    @training = Training.published.find(params[:id])
    render layout: false
  rescue ActiveRecord::RecordNotFound
    redirect_to trainings_path, alert: "Formation non trouvée"
  end
  
  def catalog_pdf
    @trainings = Training.published.ordered_by_priority
    
    # Filtres
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @trainings = @trainings.where(
        "title LIKE ? OR description LIKE ? OR training_type LIKE ?", 
        search_term, search_term, search_term
      )
    end
    
    if params[:type].present?
      @trainings = @trainings.where("LOWER(training_type) LIKE ?", "%#{params[:type].downcase}%")
    end
    
    render layout: false
  end
end
