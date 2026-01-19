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
    
    respond_to do |format|
      format.html
      format.pdf do   
        render pdf: "formation_#{@training.title.parameterize}",
               template: 'trainings/show',
               layout: false,
               page_size: 'A4',
               margin: { top: 0, bottom: 0, left: 0, right: 0 },
               encoding: 'UTF-8'
      end
    end
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
    
    render pdf: "catalogue_formations_#{Date.today}",
           layout: false,
           page_size: 'A4',
           margin: { top: 0, bottom: 0, left: 0, right: 0 },
           encoding: 'UTF-8'
  end
end
