class CreateCourseAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :course_assignments do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :assignment_type
      t.datetime :assigned_at

      t.timestamps
    end
  end
end
