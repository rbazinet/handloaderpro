# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

puts "Seeding reference data..."

# Reloading Data Sources
puts "  → Reloading Data Sources"
ReloadingDataSource.find_or_create_by!(name: "Hodgdon Reloading")
ReloadingDataSource.find_or_create_by!(name: "Other")
ReloadingDataSource.find_or_create_by!(name: "Berger")
ReloadingDataSource.find_or_create_by!(name: "Speer")
ReloadingDataSource.find_or_create_by!(name: "Lyman")
ReloadingDataSource.find_or_create_by!(name: "Hornady")

# Cartridge Types
puts "  → Cartridge Types"
CartridgeType.find_or_create_by!(name: "Rifle")
CartridgeType.find_or_create_by!(name: "Pistol")
CartridgeType.find_or_create_by!(name: "Shotgun")

# Primer Types (associated with cartridge types)
puts "  → Primer Types"
rifle_type = CartridgeType.find_by!(name: "Rifle")
pistol_type = CartridgeType.find_by!(name: "Pistol")
shotgun_type = CartridgeType.find_by!(name: "Shotgun")

# Rifle primer types
PrimerType.find_or_create_by!(name: "Large Rifle", cartridge_type: rifle_type)
PrimerType.find_or_create_by!(name: "Large Rifle Magnum", cartridge_type: rifle_type)
PrimerType.find_or_create_by!(name: "Small Rifle", cartridge_type: rifle_type)
PrimerType.find_or_create_by!(name: "Small Rifle Magnum", cartridge_type: rifle_type)

# Pistol primer types
PrimerType.find_or_create_by!(name: "Small Pistol", cartridge_type: pistol_type)
PrimerType.find_or_create_by!(name: "Large Pistol", cartridge_type: pistol_type)
PrimerType.find_or_create_by!(name: "Small Pistol Magnum", cartridge_type: pistol_type)
PrimerType.find_or_create_by!(name: "Large Pistol Magnum", cartridge_type: pistol_type)

# Shotgun primer types
PrimerType.find_or_create_by!(name: "209", cartridge_type: shotgun_type)

# Manufacturer Types
puts "  → Manufacturer Types"
ManufacturerType.find_or_create_by!(name: "Bullet")
ManufacturerType.find_or_create_by!(name: "Primer")
powder_mfg_type = ManufacturerType.find_or_create_by!(name: "Powder")

# Powder Manufacturers
puts "  → Powder Manufacturers"
hodgdon = Manufacturer.find_or_initialize_by(name: "Hodgdon")
hodgdon.manufacturer_type = powder_mfg_type
hodgdon.save!

alliant = Manufacturer.find_or_initialize_by(name: "Alliant")
alliant.manufacturer_type = powder_mfg_type
alliant.save!

winchester = Manufacturer.find_or_initialize_by(name: "Winchester")
winchester.manufacturer_type = powder_mfg_type
winchester.save!

# Powders (ensure common pistol powders exist)
puts "  → Powders"
[
  ["HP-38", winchester], ["231", winchester], ["WST", winchester], ["WSF", winchester], ["WAP", winchester],
  ["Unique", alliant], ["Universal", alliant], ["Red Dot", alliant], ["Green Dot", alliant],
  ["Blue Dot", alliant], ["Bullseye", alliant], ["Power Pistol", alliant],
  ["Titegroup", hodgdon], ["CFE Pistol", hodgdon]
].each do |powder_name, manufacturer|
  powder = Powder.find_or_initialize_by(name: powder_name)
  powder.manufacturer = manufacturer if powder.new_record?
  powder.save! if powder.changed?
end

# Powder-Cartridge Type Associations
puts "  → Powder-Cartridge Type Associations"
rifle_type = CartridgeType.find_by!(name: "Rifle")
pistol_type = CartridgeType.find_by!(name: "Pistol")
shotgun_type = CartridgeType.find_by!(name: "Shotgun")

# Associate most powders with rifle cartridge type (excluding pistol-only powders)
pistol_only_powders = ["HP-38", "231"]
Powder.find_each do |powder|
  unless pistol_only_powders.include?(powder.name)
    CartridgeTypePowder.find_or_create_by!(cartridge_type: rifle_type, powder: powder)
  end
end

# Specific powders that can also be used with pistol cartridges
pistol_powder_names = [
  "Titegroup", "231", "HP-38", "Unique", "Universal", "Red Dot", "Green Dot",
  "Blue Dot", "CFE Pistol", "Power Pistol", "Bullseye", "WST", "WSF", "WAP"
]

pistol_powder_names.each do |powder_name|
  powder = Powder.find_by(name: powder_name)
  if powder
    CartridgeTypePowder.find_or_create_by!(cartridge_type: pistol_type, powder: powder)
  end
end

# Shotgun powders (if any exist)
shotgun_powder_names = [
  "Longshot", "Blue Dot", "Green Dot", "Red Dot", "800-X", "HS-6", "HS-7",
  "Universal", "Unique", "Steel", "Nitro 100", "SR 4756", "IMR 4227"
]

shotgun_powder_names.each do |powder_name|
  powder = Powder.find_by(name: powder_name)
  if powder
    CartridgeTypePowder.find_or_create_by!(cartridge_type: shotgun_type, powder: powder)
  end
end

puts "Reference data seeded successfully!"
puts "  - #{ReloadingDataSource.count} Reloading Data Sources"
puts "  - #{CartridgeType.count} Cartridge Types"
puts "  - #{PrimerType.count} Primer Types"
puts "  - #{ManufacturerType.count} Manufacturer Types"
puts "  - #{Manufacturer.count} Manufacturers"
puts "  - #{Powder.count} Powders"
puts "  - #{CartridgeTypePowder.count} Powder-Cartridge Type Associations"

# Uncomment the following to create an Admin user for Production in Jumpstart Pro
#
#   user = User.create(
#     name: "Admin User",
#     email: "email@example.org",
#     password: "password",
#     password_confirmation: "password",
#     terms_of_service: true
#   )
#   Jumpstart.grant_system_admin!(user)
