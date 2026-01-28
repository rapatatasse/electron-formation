class TaskDependency < ApplicationRecord
  belongs_to :task
  belongs_to :dependency_task, class_name: 'Task'
end
