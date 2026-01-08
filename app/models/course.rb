class Course < ApplicationRecord
  has_many :course_assignments, dependent: :destroy
  has_many :users, through: :course_assignments
  has_many :formateurs, -> { where(course_assignments: { assignment_type: 'formateur' }) }, through: :course_assignments, source: :user
  has_many :apprenants, -> { where(course_assignments: { assignment_type: 'apprenant' }) }, through: :course_assignments, source: :user
  has_many :quizzes, dependent: :destroy

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }

  private

  def generate_slug
    self.slug = title.parameterize
  end
end
