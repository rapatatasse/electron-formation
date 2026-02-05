class AddTrainingCategoryToTrainings < ActiveRecord::Migration[7.2]
  def change
    add_column :trainings, :training_category, :string
  end
end
