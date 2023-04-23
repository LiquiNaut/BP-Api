class TableInit < ActiveRecord::Migration[7.0]
  def change
    create_table :countries do |t|
      t.string :codelist_code
      t.string :code
      t.string :name

      t.timestamps
    end

    create_table :legal_entities do |t|
      t.string :ico
      t.string :dic
      t.string :first_name
      t.string :last_name
      t.string :entity_name #nazov firmy
      t.datetime :valid_from
      t.datetime :valid_to

      t.timestamps
    end

    create_table :municipalities do |t|
      t.string :codelist_code
      t.string :code
      t.string :name

      t.timestamps
    end

    create_table :addresses do |t|
      t.string :street
      t.integer :reg_number
      t.string :building_number
      t.string :postal_code
      t.references :legal_entity, foreign_key: true, null: false
      t.references :country, foreign_key: true, null: false
      t.references :municipality, foreign_key: true, null: true

      t.timestamps
    end
  end
end
