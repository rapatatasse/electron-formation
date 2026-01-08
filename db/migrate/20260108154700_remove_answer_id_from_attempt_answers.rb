class RemoveAnswerIdFromAttemptAnswers < ActiveRecord::Migration[7.2]
  def change
    remove_reference :attempt_answers, :answer, foreign_key: true
    change_column_null :attempt_answers, :answer_ids, false
    rename_column :attempt_answers, :is_correct, :correct
  end
end
