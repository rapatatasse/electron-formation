class Answer < ApplicationRecord
  belongs_to :question
  has_many :attempt_answers, dependent: :destroy

  validates :answer_text, presence: true

  scope :correct, -> { where(correct: true) }
  scope :incorrect, -> { where(correct: false) }
  scope :ordered, -> { order(position: :asc) }
end
