class Admin::QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_quiz, only: [:show, :edit, :update, :destroy, :assign_users, :update_assignments]

  def index
    @quizzes = Quiz.includes(:creator, :questions).order(created_at: :desc)
  end

  def show
    @questions = @quiz.questions.includes(:answers, :theme).ordered
    @assignments = @quiz.quiz_assignments.includes(:user).order('users.last_name')
  end

  def new
    @quiz = Quiz.new
  end

  def create
    @quiz = current_user.created_quizzes.build(quiz_params)
    
    if @quiz.save
      redirect_to admin_quiz_path(@quiz), notice: "Quiz créé avec succès"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @quiz.update(quiz_params)
      redirect_to admin_quiz_path(@quiz), notice: "Quiz mis à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quiz.destroy
    redirect_to admin_quizzes_path, notice: "Quiz supprimé"
  end

  def assign_users
    @apprenants = User.apprenant.order(:last_name, :first_name)
    @sessions = User.apprenant.where.not(session: nil).distinct.pluck(:session).compact.sort
    @assigned_user_ids = @quiz.quiz_assignments.pluck(:user_id)
  end

  def update_assignments
    user_ids = params[:user_ids]&.reject(&:blank?) || []
    
    # Supprimer les assignations non cochées
    @quiz.quiz_assignments.where.not(user_id: user_ids).destroy_all
    
    # Ajouter les nouvelles assignations
    user_ids.each do |user_id|
      @quiz.quiz_assignments.find_or_create_by(user_id: user_id) do |assignment|
        assignment.assigned_by = current_user
        assignment.due_date = params[:due_date] if params[:due_date].present?
      end
    end
    
    redirect_to admin_quiz_path(@quiz), notice: "Assignations mises à jour (#{user_ids.count} apprenants)"
  end

  private

  def set_quiz
    @quiz = Quiz.find(params[:id])
  end

  def quiz_params
    params.require(:quiz).permit(:title, :description, :quiz_type, :time_limit, 
                                  :passing_score, :max_attempts, :randomize_questions, :active)
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
