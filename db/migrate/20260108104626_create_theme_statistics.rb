class CreateThemeStatistics < ActiveRecord::Migration[7.2]
  def change
    create_table :theme_statistics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :theme, null: false, foreign_key: true
      t.integer :questions_answered
      t.integer :correct_answers
      t.float :success_rate
      t.float :average_difficulty
      t.datetime :last_updated_at

      t.timestamps
    end
  end
end
