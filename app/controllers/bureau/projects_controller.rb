class Bureau::ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_bureau
  before_action :set_project, only: [:show, :edit, :update, :destroy, :gantt, :list, :todo, :gantt_data, :gantt_users]

  def index
    @projects = Project.order(created_at: :desc)
  end

  def show
    @tasks = @project.tasks.order(:start_date, :end_date, :created_at)
    @view = params[:view] || 'gantt'
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    @project.creator = current_user

    if @project.save
      redirect_to bureau_project_path(@project), notice: "Projet créé"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to bureau_project_path(@project), notice: "Projet mis à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @project.creator_id == current_user.id
      redirect_to bureau_projects_path, alert: "Suppression non autorisée"
      return
    end

    @project.destroy
    redirect_to bureau_projects_path, notice: "Projet supprimé"
  end

  def gantt
    redirect_to bureau_project_path(@project, view: 'gantt')
  end

  def list
    redirect_to bureau_project_path(@project, view: 'list')
  end

  def todo
    redirect_to bureau_project_path(@project, view: 'todo')
  end

  def gantt_data
    tasks = @project.tasks.includes(:users).order(:start_date, :end_date, :created_at)

    rendered_tasks = tasks.map do |t|
      start_date = t.start_date || @project.start_date || Date.current
      end_date = t.end_date || start_date

      {
        id: t.id,
        text: t.name,
        start_date: start_date.to_s,
        end_date: end_date.to_s,
        progress: t.progress.to_i,
        status: t.status,
        priority: t.priority,
        description: t.description,
        user_ids: t.user_ids
      }
    end

    links = TaskDependency
      .joins(:task)
      .where(tasks: { project_id: @project.id })
      .order(:id)
      .map do |dep|
        {
          id: dep.id,
          source: dep.dependency_task_id,
          target: dep.task_id,
          type: 0,
          dependency_id: dep.id
        }
      end

    render json: { tasks: rendered_tasks, links: links }
  end

  def gantt_users
    users = User.order(:last_name, :first_name)
    render json: users.map { |u| { id: u.id, full_name: u.full_name, email: u.email } }
  end

  private

  def require_bureau
    unless current_user.bureau? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :start_date, :end_date, :status, :manager)
  end
end
