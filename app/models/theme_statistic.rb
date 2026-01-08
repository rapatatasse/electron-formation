class ThemeStatistic < ApplicationRecord
  belongs_to :user
  belongs_to :theme

  validates :user_id, uniqueness: { scope: :theme_id }

  def update_statistics!
    user_answers = AttemptAnswer.joins(quiz_attempt: :user, question: :theme)
                                 .where(users: { id: user_id }, themes: { id: theme_id })
    
    self.questions_answered = user_answers.count
    self.correct_answers = user_answers.correct.count
    self.success_rate = questions_answered.zero? ? 0 : (correct_answers.to_f / questions_answered * 100).round(2)
    self.average_difficulty = user_answers.correct.average(:question_difficulty)&.round(2) || 0
    self.last_updated_at = Time.current
    
    save
  end
end
