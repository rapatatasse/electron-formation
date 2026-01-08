class Answer < ApplicationRecord
  belongs_to :question
  has_many :attempt_answers, dependent: :destroy

  validates :answer_text, presence: true

  scope :correct, -> { where(is_correct: true) }
  scope :incorrect, -> { where(is_correct: false) }
  scope :ordered, -> { order(position: :asc) }
end
