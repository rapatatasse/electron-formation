class Formateur::QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_formateur
  before_action :set_quiz, only: [:show, :edit, :update, :destroy]

  def index
    @quizzes = current_user.created_quizzes.order(created_at: :desc)
  end

  def show
    @questions = @quiz.questions.includes(:answers, :theme).ordered
    @attempts = @quiz.quiz_attempts.completed.recent.limit(10)
  end

 

  private

  def set_quiz
    @quiz = current_user.created_quizzes.find(params[:id])
  end

  def quiz_params
    params.require(:quiz).permit(:title, :description, :quiz_type, :time_limit, 
                                  :passing_score, :max_attempts, :randomize_questions, :active)
  end

  def require_formateur
    unless current_user.formateur? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
