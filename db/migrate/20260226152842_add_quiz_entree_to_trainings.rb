class AddQuizEntreeToTrainings < ActiveRecord::Migration[7.2]
  def change
    add_column :trainings, :quiz_entrance, :text
    add_column :trainings, :quiz_exit, :text
  end
end
