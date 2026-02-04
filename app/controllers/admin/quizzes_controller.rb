class Admin::QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_quiz, only: [:show, :edit, :update, :destroy, :create_quiz_session]

  def index
    @quizzes = Quiz.includes( :questions).order(created_at: :desc)
  end

  def show
    @questions = @quiz.questions.includes(:answers, :theme).ordered
    @quiz_sessions = @quiz.quiz_sessions.order(created_at: :desc)
  end

  def new
    @quiz = Quiz.new
  end

  def create
    @quiz = Quiz.build(quiz_params)
    
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

  def create_quiz_session
    quiz_session = QuizSession.create_from_quiz!(@quiz, created_by: current_user)
    redirect_to admin_quiz_path(@quiz), notice: "Session créée: #{quiz_session.public_url}"
  rescue => e
    redirect_to admin_quiz_path(@quiz), alert: e.message
  end

  private

  def set_quiz
    @quiz = Quiz.find(params[:id])
  end

  def quiz_params
    permitted = params.require(:quiz).permit(:description, :quiz_type, :time_limit,
                                            :passing_score, :randomize_questions, :active, :question_count)

    title = params.dig(:quiz, :title)
    if title.is_a?(ActionController::Parameters)
      permitted[:title] = title.to_unsafe_h
    elsif title.is_a?(Hash)
      permitted[:title] = title
    elsif title.present?
      permitted[:title] = { 'fr' => title }
    end

    permitted
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
