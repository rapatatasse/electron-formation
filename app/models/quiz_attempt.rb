class QuizAttempt < ApplicationRecord
  belongs_to :quiz
  belongs_to :user
  has_many :attempt_answers, dependent: :destroy
  has_one :certificate, dependent: :destroy

  validates :status, inclusion: { in: %w[in_progress completed abandoned] }

  scope :completed, -> { where(status: 'completed') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }
  scope :recent, -> { order(created_at: :desc) }

  before_create :set_started_at
  before_create :set_initial_level, if: -> { quiz.adaptatif? }

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
    return 0 if total_questions.zero?
    
    (correct_answers_count.to_f / total_questions * 100).round
  end

  def total_questions
    quiz.questions.count
  end

  def correct_answers_count
    attempt_answers.where(correct: true).count
  end

  def next_question
    answered_question_ids = attempt_answers.pluck(:question_id)
    quiz.questions.where.not(id: answered_question_ids).order(:position).first
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

  private

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
