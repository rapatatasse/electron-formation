class Bureau::TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :require_bureau
  before_action :set_task, only: [:show, :edit, :update, :destroy]
  before_action :set_project, only: [:new, :create]
  before_action :set_users, only: [:new, :edit]

  def index
    @tasks = Task.includes(:project).order(:start_date, :end_date, :created_at)
  end

  def show
  end

  def new
    @task = @project.tasks.new
  end

  def create
    @task = @project.tasks.new(task_params)

    if @task.save
      assign_users_from_params
      redirect_to bureau_project_path(@project, view: 'list'), notice: "Tâche créée"
    else
      set_users
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      assign_users_from_params
      if request.format.json?
        render json: {
          id: @task.id,
          text: @task.name,
          start_date: @task.start_date&.to_s,
          end_date: @task.end_date&.to_s,
          progress: @task.progress.to_i,
          status: @task.status,
          priority: @task.priority,
          description: @task.description,
          user_ids: @task.user_ids
        }
      else
        redirect_to bureau_task_path(@task), notice: "Tâche mise à jour"
      end
    else
      if request.format.json?
        render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
      else
        set_users
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    project = @task.project
    @task.destroy
    redirect_to bureau_project_path(project, view: 'list'), notice: "Tâche supprimée"
  end

  def calendar
    @days = params[:days].to_i
    @days = 14 if @days <= 0

    @start_date = begin
      params[:start].present? ? Date.parse(params[:start]) : Date.current
    rescue ArgumentError
      Date.current
    end

    @end_date = @start_date + (@days - 1).days
    @prev_start = @start_date - @days.days
    @next_start = @start_date + @days.days

    @tasks = Task
      .includes(:project)
      .where.not(start_date: nil)
      .where("tasks.start_date <= ? AND (tasks.end_date IS NULL OR tasks.end_date >= ?)", @end_date, @start_date)
      .order(:start_date)
  end

  def todo
    @tasks = Task.includes(:project).where("progress < 100").order(:end_date, :start_date, :created_at)
  end

  private

  def require_bureau
    unless current_user.bureau? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end

  def set_task
    @task = Task.find(params[:id])
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def task_params
    params.require(:task).permit(:name, :description, :start_date, :end_date, :duration_days, :hours_per_day, :progress, :status, :priority)
  end

  def set_users
    @users = User.bureau.order(:last_name, :first_name)
    
  end

  def assign_users_from_params
    return unless params[:task]
    return unless params[:task].key?(:user_ids)

    ids = Array(params[:task][:user_ids]).reject(&:blank?).map(&:to_i)
    @task.user_ids = ids
  end
end
