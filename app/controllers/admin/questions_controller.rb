class Admin::QuestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_quiz
  before_action :set_question, only: [:edit, :update, :destroy]

  def index
    @questions = @quiz.questions.includes(:theme, :answers).order(:position)
  end

  def new
    @question = @quiz.questions.build
    3.times { @question.answers.build }
  end

  def create
    @question = @quiz.questions.build(question_params)
    
    if @question.save
      redirect_to admin_quiz_path(@quiz), notice: "Question créée avec succès"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @question.update(question_params)
      redirect_to admin_quiz_path(@quiz), notice: "Question mise à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question.destroy
    redirect_to admin_quiz_path(@quiz), notice: "Question supprimée"
  end

  def destroy_all
    count = @quiz.questions.count
    @quiz.questions.destroy_all
    redirect_to admin_quiz_path(@quiz), notice: "#{count} question(s) supprimée(s) avec succès"
  end

  def import
  end

  def process_import
    unless params[:file].present?
      redirect_to import_admin_quiz_questions_path(@quiz), alert: "Veuillez sélectionner un fichier CSV"
      return
    end

    result = Question.import_from_csv(@quiz, params[:file].path)
    
    if result[:errors].any?
      flash[:alert] = "#{result[:count]} questions importées avec #{result[:errors].count} erreurs : #{result[:errors].first(3).join('; ')}"
    else
      flash[:notice] = "#{result[:count]} questions importées avec succès"
    end
    
    redirect_to admin_quiz_path(@quiz)
  end

  def export
    csv_data = Question.export_to_csv(@quiz)
    send_data csv_data, 
              filename: "questions_#{@quiz.title.parameterize}_#{Date.today}.csv", 
              type: 'text/csv; charset=utf-8'
  end

  def download_template
    send_data Question.csv_template, 
              filename: "template_import_questions.csv", 
              type: 'text/csv; charset=utf-8'
  end

  private

  def set_quiz
    @quiz = Quiz.find(params[:quiz_id])
  end

  def set_question
    @question = @quiz.questions.find(params[:id])
  end

  def question_params
    permitted = params.require(:question).permit(
      :theme_id, :image_url, :difficulty_level, :position,
      :multiple_correct_answers,
      answers_attributes: [:id, :answer_text, :correct, :_destroy]
    )

    question_text = params.dig(:question, :question_text)
    if question_text.is_a?(ActionController::Parameters)
      permitted[:question_text] = question_text.to_unsafe_h
    elsif question_text.is_a?(Hash)
      permitted[:question_text] = question_text
    elsif question_text.present?
      permitted[:question_text] = { 'fr' => question_text }
    end

    permitted
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
