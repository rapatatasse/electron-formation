class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false, limit: 150
      t.text :description
      t.date :start_date
      t.date :end_date
      t.integer :duration_days
      t.integer :hours_per_day
      t.integer :progress, null: false, default: 0
      t.string :status, limit: 50
      t.string :priority, limit: 20

      t.timestamps
    end
  end
end
