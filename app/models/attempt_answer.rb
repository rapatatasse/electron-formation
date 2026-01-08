class AttemptAnswer < ApplicationRecord
  belongs_to :quiz_attempt
  belongs_to :question
  has_many :answers, foreign_key: :id, primary_key: :answer_ids

  validates :answer_ids, presence: true

  scope :ordered, -> { order(created_at: :asc) }
  scope :correct, -> { where(correct: true) }
  scope :incorrect, -> { where(correct: false) }

  # Getter pour answer_ids depuis JSON
  def answer_ids
    read_attribute(:answer_ids) || []
  end

  # Setter pour answer_ids
  def answer_ids=(ids)
    write_attribute(:answer_ids, ids.is_a?(Array) ? ids.map(&:to_i) : [ids.to_i])
  end

  # Récupérer les objets Answer associés
  def answers
    Answer.where(id: answer_ids)
  end

  def check_correctness!
    correct_ids = question.answers.where(is_correct: true).pluck(:id).sort
    selected_ids = answer_ids.map(&:to_i).sort
    
    update(correct: correct_ids == selected_ids)
  end

  # Méthode pour compatibilité avec les vues
  def is_correct?
    correct == true
  end
end
