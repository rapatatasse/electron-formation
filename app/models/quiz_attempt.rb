class QuizAttempt < ApplicationRecord
  belongs_to :quiz
  belongs_to :user
  belongs_to :assigned_by, class_name: 'User', foreign_key: 'assigned_by_id', optional: true
  has_one :certificate, dependent: :destroy

  validates :status, inclusion: { in: %w[in_progress completed abandoned] }, allow_nil: true

  scope :completed, -> { where(status: 'completed') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :assigned, -> { where.not(assigned_at: nil) }
  scope :not_started, -> { where(started_at: nil) }
  scope :overdue, -> { where('due_date < ? AND status != ?', Time.current, 'completed') }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_quiz, ->(quiz) { where(quiz: quiz) }

  before_create :set_assigned_at, if: -> { assigned_at.nil? && assigned_by_id.present? }
  before_create :set_started_at, if: -> { status.present? }
  before_create :set_initial_level, if: -> { quiz.adaptatif? && status.present? }
  before_create :initialize_answers_data

  def complete!
    calculated_score = calculate_score
    update(
      status: 'completed',
      completed_at: Time.current,
      score: calculated_score,
      passed: quiz.passing_score ? calculated_score >= quiz.passing_score : true
    )
  end

  def calculate_score
    return 0 if total_questions_count.zero?
    
    (correct_answers_count.to_f / total_questions_count * 100).round
  end

  def total_questions_count
    (answers_data || []).length
  end

  def correct_answers_count
    (answers_data || []).count { |answer| answer['correct'] == true }
  end

  def next_question
    answered_question_ids = (answers_data || []).map { |a| a['question_id'] }
    quiz.questions.where.not(id: answered_question_ids).order(:position).first
  end
  
  def add_answer(question, selected_answer_ids)
    # Récupérer les informations complètes de la question et des réponses
    question_data = {
      question_id: question.id,
      question_text: question.question_text,
      question_updated_at: question.updated_at.iso8601,
      answer_ids: selected_answer_ids,
      answers: question.answers.map do |answer|
        {
          id: answer.id,
          text: answer.answer_text,
          correct: answer.correct,
          updated_at: answer.updated_at.iso8601
        }
      end,
      correct: check_answer_correctness(question, selected_answer_ids),
      position: (answers_data || []).length + 1,
      answered_at: Time.current.iso8601
    }
    
    self.answers_data ||= []
    self.answers_data << question_data
    save!
    
    question_data
  end
  
  def get_valid_answers
    return [] unless answers_data
    
    answers_data.select do |answer_data|
      question = quiz.questions.find_by(id: answer_data['question_id'])
      next false unless question
      
      # Vérifier si la question a été modifiée après la tentative
      question_updated = DateTime.parse(answer_data['question_updated_at'])
      question.updated_at <= question_updated + 1.second # Tolérance de 1 seconde
    end
  end
  
  private
  
  def check_answer_correctness(question, selected_answer_ids)
    correct_answer_ids = question.answers.where(correct: true).pluck(:id).sort
    selected_answer_ids.map(&:to_i).sort == correct_answer_ids
  end

  def completed?
    status == 'completed'
  end

  def passed?
    passed == true
  end

  def duration_in_seconds
    return 0 unless completed_at && started_at
    (completed_at - started_at).to_i
  end

  def level_category
    return nil unless final_level

    case final_level
    when 0..30
      'debutant'
    when 31..60
      'intermediaire'
    when 61..90
      'avance'
    when 91..100
      'expert'
    end
  end

  def overdue?
    due_date.present? && due_date < Time.current && status != 'completed'
  end

  def assigned?
    assigned_at.present?
  end

  def started?
    started_at.present?
  end

  def initialize_answers_data
    self.answers_data ||= []
  end

  def set_assigned_at
    self.assigned_at ||= Time.current
  end

  def set_started_at
    self.started_at ||= Time.current
  end

  def set_initial_level
    self.initial_level ||= 50
  end

  def update_quiz_statistics
    QuizStatisticsUpdateJob.perform_later(quiz.id)
  end
end
