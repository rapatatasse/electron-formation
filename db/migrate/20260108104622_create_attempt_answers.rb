class CreateAttemptAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :attempt_answers do |t|
      t.references :quiz_attempt, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :answer, null: false, foreign_key: true
      t.json :answer_ids
      t.boolean :is_correct
      t.integer :question_difficulty
      t.integer :user_level_at_time
      t.integer :time_spent
      t.integer :position

      t.timestamps
    end
  end
end
