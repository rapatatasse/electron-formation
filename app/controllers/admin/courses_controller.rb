class Admin::CoursesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_course, only: [:show, :edit, :update, :destroy]

  def index
    @courses = Course.ordered
  end

  def show
  end

  def new
    @course = Course.new
  end

  def create
    @course = Course.new(course_params)
    
    if @course.save
      redirect_to admin_courses_path, notice: "Cours créé avec succès"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @course.update(course_params)
      redirect_to admin_courses_path, notice: "Cours mis à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course.destroy
    redirect_to admin_courses_path, notice: "Cours supprimé"
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:title, :description, :slug, :content, :position, :active)
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
