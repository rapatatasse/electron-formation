class QuizParticipant < ApplicationRecord
  belongs_to :quiz_session

  has_many :quiz_attempts, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :identifier, presence: true
  validates :identifier, uniqueness: { scope: :quiz_session_id }

  before_validation :set_identifier

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def set_identifier
    return if first_name.blank? || last_name.blank?

    self.identifier = "#{first_name} #{last_name}".downcase.strip.gsub(/\s+/, ' ')
  end
end
