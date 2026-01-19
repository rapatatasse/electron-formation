class CreateTrainings < ActiveRecord::Migration[7.2]
  def change
    create_table :trainings do |t|
      t.string :title, null: false
      t.decimal :price_intra_ht, precision: 10, scale: 2
      t.decimal :price_inter_ht, precision: 10, scale: 2
      t.string :training_type
      t.string :image_url
      t.string :duration
      t.text :description
      t.text :objective
      t.text :program
      t.text :target_audience
      t.text :teaching_methods
      t.text :prerequisites
      t.integer :priority, default: 0
      t.text :evaluation_method
      t.boolean :published, default: false

      t.timestamps
    end
    
    add_index :trainings, :title
    add_index :trainings, :published
    add_index :trainings, :priority
  end
end
