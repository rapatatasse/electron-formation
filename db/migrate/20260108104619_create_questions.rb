class CreateQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :questions do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :theme, null: false, foreign_key: true
      t.text :question_text
      t.string :image_url
      t.integer :difficulty_level
      t.boolean :multiple_correct_answers
      t.integer :position #dans le quiz

      t.timestamps
    end
  end
end
