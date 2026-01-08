class Certificate < ApplicationRecord
  belongs_to :quiz_attempt
  belongs_to :user
  belongs_to :issued_by, class_name: 'User', foreign_key: 'issued_by_id'

  validates :certificate_number, presence: true, uniqueness: true
  validates :score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :level, inclusion: { in: %w[debutant intermediaire avance expert] }

  before_validation :generate_certificate_number, if: -> { certificate_number.blank? }
  before_create :set_issued_at

  scope :recent, -> { order(issued_at: :desc) }
  scope :by_level, ->(level) { where(level: level) }

  private

  def generate_certificate_number
    self.certificate_number = "CERT-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def set_issued_at
    self.issued_at ||= Time.current
  end
end
