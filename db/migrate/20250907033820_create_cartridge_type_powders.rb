class CreateCartridgeTypePowders < ActiveRecord::Migration[8.0]
  def change
    create_table :cartridge_type_powders do |t|
      t.references :cartridge_type, null: false, foreign_key: true
      t.references :powder, null: false, foreign_key: true

      t.timestamps
    end

    add_index :cartridge_type_powders, [:cartridge_type_id, :powder_id], unique: true
  end
end
