class Task < ApplicationRecord
  belongs_to :project

  has_many :task_users, dependent: :destroy
  has_many :users, through: :task_users

  has_many :task_dependencies, dependent: :destroy
  has_many :dependencies, through: :task_dependencies, source: :dependency_task

  has_many :dependent_task_dependencies, class_name: 'TaskDependency', foreign_key: :dependency_task_id, dependent: :destroy
  has_many :dependents, through: :dependent_task_dependencies, source: :task

  validates :name, presence: true
  validates :progress, inclusion: { in: 0..100 }
end
