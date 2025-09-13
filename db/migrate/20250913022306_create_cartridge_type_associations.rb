class CreateCartridgeTypeAssociations < ActiveRecord::Migration[8.1]
  def change
    # Create cartridge_type_cartridges join table
    create_table :cartridge_type_cartridges do |t|
      t.references :cartridge_type, null: false, foreign_key: true
      t.references :cartridge, null: false, foreign_key: true
      t.timestamps
    end

    # Create cartridge_type_bullet_weights join table
    create_table :cartridge_type_bullet_weights do |t|
      t.references :cartridge_type, null: false, foreign_key: true
      t.references :bullet_weight, null: false, foreign_key: true
      t.timestamps
    end

    # Create cartridge_type_manufacturers join table
    create_table :cartridge_type_manufacturers do |t|
      t.references :cartridge_type, null: false, foreign_key: true
      t.references :manufacturer, null: false, foreign_key: true
      t.timestamps
    end

    # Add unique indexes to prevent duplicate associations
    add_index :cartridge_type_cartridges, [:cartridge_type_id, :cartridge_id], unique: true, name: "index_cartridge_type_cartridges_unique"
    add_index :cartridge_type_bullet_weights, [:cartridge_type_id, :bullet_weight_id], unique: true, name: "index_cartridge_type_bullet_weights_unique"
    add_index :cartridge_type_manufacturers, [:cartridge_type_id, :manufacturer_id], unique: true, name: "index_cartridge_type_manufacturers_unique"
  end
end
