class CreateQuizzes < ActiveRecord::Migration[7.2]
  def change
    create_table :quizzes do |t|
      t.string :title
      t.text :description
      t.references :creator, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :quiz_type
      t.integer :question_count
      t.integer :time_limit
      t.integer :passing_threshold
      t.boolean :randomize_questions
      t.boolean :randomize_answers
      t.boolean :certificate_enabled
      t.boolean :active

      t.timestamps
    end
  end
end
