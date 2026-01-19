class Session < ApplicationRecord
  has_many :user_sessions, dependent: :destroy
  has_many :users, through: :user_sessions

  validates :name, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
