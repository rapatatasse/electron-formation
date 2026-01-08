class CreateCertificates < ActiveRecord::Migration[7.2]
  def change
    create_table :certificates do |t|
      t.references :quiz_attempt, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :issued_by, null: false, foreign_key: true
      t.string :certificate_number
      t.integer :score
      t.string :level
      t.string :pdf_url
      t.datetime :issued_at

      t.timestamps
    end
    add_index :certificates, :certificate_number, unique: true
  end
end
