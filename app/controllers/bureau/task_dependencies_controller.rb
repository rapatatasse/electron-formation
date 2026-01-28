class Bureau::TaskDependenciesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_bureau

  def create
    dependency = TaskDependency.new(task_dependency_params)

    if dependency.save
      render json: { id: dependency.id }, status: :created
    else
      render json: { errors: dependency.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    dependency = TaskDependency.find(params[:id])
    dependency.destroy
    head :no_content
  end

  private

  def require_bureau
    unless current_user.bureau? || current_user.admin?
      render json: { error: 'Accès non autorisé' }, status: :forbidden
    end
  end

  def task_dependency_params
    params.require(:task_dependency).permit(:task_id, :dependency_task_id)
  end
end
