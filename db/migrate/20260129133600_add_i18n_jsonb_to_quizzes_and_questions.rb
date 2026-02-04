class AddI18nJsonbToQuizzesAndQuestions < ActiveRecord::Migration[7.2]
  def up
    add_column :quizzes, :title_tmp, :jsonb, default: {}, null: false
    execute <<~SQL
      UPDATE quizzes
      SET title_tmp = CASE
        WHEN title IS NULL OR title = '' THEN '{}'::jsonb
        ELSE jsonb_build_object('fr', title)
      END
    SQL
    remove_column :quizzes, :title
    rename_column :quizzes, :title_tmp, :title

    add_column :questions, :question_text_tmp, :jsonb, default: {}, null: false
    execute <<~SQL
      UPDATE questions
      SET question_text_tmp = CASE
        WHEN question_text IS NULL OR question_text = '' THEN '{}'::jsonb
        ELSE jsonb_build_object('fr', question_text)
      END
    SQL
    remove_column :questions, :question_text
    rename_column :questions, :question_text_tmp, :question_text
  end

  def down
    add_column :quizzes, :title_tmp, :string
    execute <<~SQL
      UPDATE quizzes
      SET title_tmp = COALESCE(title->>'fr', '')
    SQL
    remove_column :quizzes, :title
    rename_column :quizzes, :title_tmp, :title

    add_column :questions, :question_text_tmp, :text
    execute <<~SQL
      UPDATE questions
      SET question_text_tmp = COALESCE(question_text->>'fr', '')
    SQL
    remove_column :questions, :question_text
    rename_column :questions, :question_text_tmp, :question_text
  end
end
