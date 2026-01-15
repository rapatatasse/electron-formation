class Quiz < ApplicationRecord

  belongs_to :course, optional: true
  has_many :questions, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  has_many :assigned_users, through: :quiz_attempts, source: :user
  has_one :quiz_statistic, dependent: :destroy

  enum quiz_type: { simple: 0, adaptatif: 1 }

  validates :title, presence: true
  validates :quiz_type, presence: true
  validates :passing_score, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :question_count, numericality: { only_integer: true, greater_than: 0 }, if: -> { question_count.present? }
  validates :time_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :simple_quizzes, -> { where(quiz_type: :simple) }
  scope :adaptive_quizzes, -> { where(quiz_type: :adaptatif) }



  def questions_count
    questions.count
  end

  def attempts_count
    quiz_attempts.count
  end

 

  def adaptive?
    quiz_type == :adaptive
  end

  private


end
