class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects do |t|
      t.string :name, null: false, limit: 150
      t.text :description
      t.date :start_date
      t.date :end_date
      t.string :status, limit: 50
      t.string :manager, limit: 100
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
