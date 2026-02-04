class QuizSession < ApplicationRecord
  belongs_to :quiz
  belongs_to :created_by, class_name: 'User', foreign_key: :created_by_id

  has_many :quiz_participants, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy

  validates :token, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def public_url
    Rails.application.routes.url_helpers.quiz_session_url(token, host: default_host)
  end

  def public_path
    Rails.application.routes.url_helpers.quiz_session_path(token)
  end

  def ordered_question_ids
    (answers_data || []).map { |h| h['question_id'] || h[:question_id] }.compact.map(&:to_i)
  end

  def self.create_from_quiz!(quiz, created_by:)
    question_ids = select_questions_for_quiz(quiz)

    create!(
      quiz: quiz,
      created_by: created_by,
      token: SecureRandom.hex(16),
      active: true,
      answers_data: question_ids.map { |id| { question_id: id } }
    )
  end

  def self.select_questions_for_quiz(quiz)
    desired_count = quiz.question_count.presence || quiz.questions.count
    available = quiz.questions.includes(:theme).to_a

    return available.sort_by(&:position).map(&:id) if desired_count >= available.length

    by_theme = available.group_by(&:theme_id)
    total = available.length.to_f

    allocations = by_theme.map do |theme_id, questions|
      raw = (questions.length / total) * desired_count
      { theme_id: theme_id, raw: raw, base: raw.floor, frac: raw - raw.floor }
    end

    base_sum = allocations.sum { |a| a[:base] }
    remainder = desired_count - base_sum

    allocations.sort_by { |a| -a[:frac] }.first(remainder).each { |a| a[:base] += 1 }

    selected = []
    allocations.each do |a|
      questions = by_theme[a[:theme_id]]
      count = [a[:base], questions.length].min
      selected.concat(questions.shuffle.first(count))
    end

    if selected.length < desired_count
      missing = desired_count - selected.length
      pool = (available - selected)
      selected.concat(pool.shuffle.first(missing))
    end

    selected.shuffle.first(desired_count).map(&:id)
  end

  private

  def default_host
    ENV.fetch('APP_HOST', 'localhost:3000')
  end
end
