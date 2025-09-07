class AddCartridgeTypeToPrimerTypes < ActiveRecord::Migration[8.0]
  def change
    # Add the reference column as nullable first
    add_reference :primer_types, :cartridge_type, null: true, foreign_key: true

    # Get cartridge types
    rifle_type = CartridgeType.find_by(name: "Rifle")
    pistol_type = CartridgeType.find_by(name: "Pistol")
    shotgun_type = CartridgeType.find_by(name: "Shotgun")

    # Update existing primer types with appropriate cartridge types
    if rifle_type
      PrimerType.where(name: ["Large Rifle", "Large Rifle Magnum", "Small Rifle", "Small Rifle Magnum"])
        .update_all(cartridge_type_id: rifle_type.id)
    end

    if pistol_type
      PrimerType.where(name: ["Small Pistol", "Large Pistol", "Small Pistol Magnum", "Large Pistol Magnum"])
        .update_all(cartridge_type_id: pistol_type.id)
    end

    if shotgun_type
      PrimerType.where(name: "209").update_all(cartridge_type_id: shotgun_type.id)
    end

    # Now make the column required
    change_column_null :primer_types, :cartridge_type_id, false
  end
end
