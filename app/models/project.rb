class Project < ApplicationRecord
  belongs_to :creator, class_name: 'User'

  has_many :tasks, dependent: :destroy

  validates :name, presence: true
end
