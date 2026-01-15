class Apprenant::QuizAttemptsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_apprenant
  before_action :set_attempt, only: [:show, :submit_answer, :complete]

  def index
    @attempts = current_user.quiz_attempts.includes(:quiz).order(created_at: :desc)
  end

  def new
    @quiz = Quiz.find(params[:quiz_id])
    
    # Vérifier que le quiz est assigné à l'apprenant
    assignment = current_user.quiz_attempts.assigned.find_by(quiz: @quiz)
    unless assignment
      redirect_to apprenant_dashboard_path, alert: "Ce quiz ne vous a pas été assigné"
      return
    end
    
    # Vérifier si déjà complété
    if assignment.status == 'completed' && assignment.passed?
      redirect_to apprenant_dashboard_path, notice: "Vous avez déjà complété ce quiz"
      return
    end
    
    # Vérifier le nombre de tentatives
    user_attempts = @quiz.quiz_attempts.where(user: current_user, status: ['in_progress', 'completed'])
    if @quiz.max_attempts && user_attempts.count >= @quiz.max_attempts
      redirect_to apprenant_dashboard_path, alert: "Vous avez atteint le nombre maximum de tentatives pour ce quiz"
      return
    end
    
    @attempts_count = user_attempts.count
    @assignment = assignment
  end

  def show
    # Si le quiz est terminé, afficher les résultats
    # Sinon, afficher la question suivante
    if @attempt.completed?
      @results = @attempt
    else
      @current_question = @attempt.next_question
      if @current_question.nil?
        # Toutes les questions ont été répondues, compléter automatiquement
        @attempt.complete!
        @results = @attempt
      end
    end
  end

  def create
    quiz = Quiz.find(params[:quiz_id])
    
    # Vérifier si l'utilisateur peut passer le quiz
    user_attempts = quiz.quiz_attempts.where(user: current_user, status: ['in_progress', 'completed'])
    if quiz.max_attempts && user_attempts.count >= quiz.max_attempts
      redirect_to apprenant_quiz_attempts_path, alert: "Vous avez atteint le nombre maximum de tentatives pour ce quiz"
      return
    end

    # Trouver l'assignation existante ou créer une nouvelle tentative
    assignment = current_user.quiz_attempts.assigned.find_by(quiz: quiz)
    
    if assignment && !assignment.started?
      # Démarrer l'assignation existante
      assignment.update!(
        status: 'in_progress',
        started_at: Time.current,
        initial_level: quiz.adaptive? ? 50 : nil
      )
      @attempt = assignment
    else
      # Créer une nouvelle tentative
      @attempt = current_user.quiz_attempts.create!(
        quiz: quiz,
        status: 'in_progress',
        started_at: Time.current,
        initial_level: quiz.adaptive? ? 50 : nil
      )
    end

    redirect_to apprenant_quiz_attempt_path(@attempt)
  end

  def submit_answer
    question = Question.find(params[:question_id])
    answer_ids = params[:answer_ids]&.reject(&:blank?) || []

    if answer_ids.empty?
      redirect_to apprenant_quiz_attempt_path(@attempt), alert: "Veuillez sélectionner au moins une réponse"
      return
    end

    # Ajouter la réponse avec toutes les informations en JSON
    @attempt.add_answer(question, answer_ids)

    redirect_to apprenant_quiz_attempt_path(@attempt)
  end

  def complete
    unless @attempt.completed?
      @attempt.complete!
    end

    redirect_to apprenant_quiz_attempt_path(@attempt)
  end

  private

  def set_attempt
    @attempt = current_user.quiz_attempts.find(params[:id])
  end

  def require_apprenant
    unless current_user.apprenant? || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end
