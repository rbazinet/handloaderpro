class RemoveCartridgeTypeIdFromCartridges < ActiveRecord::Migration[8.1]
  def change
    # Remove cartridge_type_id foreign key from cartridges table
    # since we're now using cartridge_type_cartridges association table
    remove_reference :cartridges, :cartridge_type, foreign_key: true
  end
end
