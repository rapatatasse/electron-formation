class CourseAssignment < ApplicationRecord
  belongs_to :course
  belongs_to :user

  validates :assignment_type, presence: true, inclusion: { in: %w[formateur apprenant] }
  validates :user_id, uniqueness: { scope: [:course_id, :assignment_type] }

  before_create :set_assigned_at

  scope :formateurs, -> { where(assignment_type: 'formateur') }
  scope :apprenants, -> { where(assignment_type: 'apprenant') }

  private

  def set_assigned_at
    self.assigned_at ||= Time.current
  end
end
