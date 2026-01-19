class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :sessions, :name, unique: true
  end
end
