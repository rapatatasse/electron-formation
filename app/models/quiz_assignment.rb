class QuizAssignment < ApplicationRecord
  belongs_to :quiz
  belongs_to :user
  belongs_to :assigned_by, class_name: 'User', foreign_key: 'assigned_by_id', optional: true

  validates :quiz_id, uniqueness: { scope: :user_id, message: "déjà assigné à cet utilisateur" }
  validates :user_id, presence: true
  validates :quiz_id, presence: true

  scope :active, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }
  scope :overdue, -> { where('due_date < ? AND completed = ?', Time.current, false) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_quiz, ->(quiz) { where(quiz: quiz) }

  before_create :set_assigned_at

  def overdue?
    due_date.present? && due_date < Time.current && !completed?
  end

  def mark_completed!
    update(completed: true)
  end

  private

  def set_assigned_at
    self.assigned_at ||= Time.current
  end
end
