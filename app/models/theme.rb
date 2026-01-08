class Theme < ApplicationRecord
  has_many :questions, dependent: :destroy
  has_many :theme_statistics, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  def questions_count
    questions.count
  end
end
