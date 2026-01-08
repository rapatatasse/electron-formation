class QuizStatistic < ApplicationRecord
  belongs_to :quiz

  validates :quiz_id, uniqueness: true

  def update_statistics!
    attempts = quiz.quiz_attempts.completed
    
    self.total_attempts = quiz.quiz_attempts.count
    self.total_completions = attempts.count
    self.average_score = attempts.average(:score)&.round(2) || 0
    self.average_time = attempts.average(:time_spent)&.round(2) || 0
    self.pass_count = attempts.passed.count
    self.fail_count = attempts.failed.count
    self.pass_rate = total_completions.zero? ? 0 : (pass_count.to_f / total_completions * 100).round(2)
    self.last_calculated_at = Time.current
    
    save
  end
end
