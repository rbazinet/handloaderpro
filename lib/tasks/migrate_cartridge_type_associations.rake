# frozen_string_literal: true

namespace :handloaderpro do
  namespace :migrate do
    desc "Migrate existing Hodgdon data to use cartridge type associations"
    task cartridge_type_associations: :environment do
      puts "🔄 Migrating existing Hodgdon data to cartridge type associations..."
      puts "=" * 60

      begin
        # Ensure rifle cartridge type exists
        rifle_type = CartridgeType.find_by(id: 1) || CartridgeType.find_by(name: "Rifle")
        unless rifle_type
          puts "❌ Rifle cartridge type not found. Please ensure cartridge types exist."
          exit 1
        end

        puts "📋 Using rifle cartridge type: #{rifle_type.name} (ID: #{rifle_type.id})"

        # Migrate existing cartridges
        migrated_cartridges = migrate_cartridges_to_associations(rifle_type)

        # Migrate existing bullet weights
        migrated_bullet_weights = migrate_bullet_weights_to_associations(rifle_type)

        # Migrate existing manufacturers (powder manufacturers)
        migrated_manufacturers = migrate_manufacturers_to_associations(rifle_type)

        # Migrate existing powders
        migrated_powders = migrate_powders_to_associations(rifle_type)

        puts "\n✅ Migration completed successfully!"
        puts "📊 Results:"
        puts "   - #{migrated_cartridges} cartridges associated with rifle type"
        puts "   - #{migrated_bullet_weights} bullet weights associated with rifle type"
        puts "   - #{migrated_manufacturers} manufacturers associated with rifle type"
        puts "   - #{migrated_powders} powders associated with rifle type"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      end
    end

    desc "Show current cartridge type association statistics"
    task association_stats: :environment do
      puts "📊 Cartridge Type Association Statistics"
      puts "=" * 60

      begin
        rifle_type = CartridgeType.find_by(id: 1) || CartridgeType.find_by(name: "Rifle")
        pistol_type = CartridgeType.find_by(id: 2) || CartridgeType.find_by(name: "Pistol")

        puts "🔫 Cartridge Types:"
        puts "   - Rifle: #{rifle_type&.name || "Not found"} (ID: #{rifle_type&.id || "N/A"})"
        puts "   - Pistol: #{pistol_type&.name || "Not found"} (ID: #{pistol_type&.id || "N/A"})"
        puts ""

        puts "📈 Association Counts:"
        puts "   - Cartridges:"
        puts "     * Rifle: #{begin
          CartridgeTypeCartridge.where(cartridge_type: rifle_type).count
        rescue
          0
        end}"
        puts "     * Pistol: #{begin
          CartridgeTypeCartridge.where(cartridge_type: pistol_type).count
        rescue
          0
        end}"
        puts "   - Bullet Weights:"
        puts "     * Rifle: #{begin
          CartridgeTypeBulletWeight.where(cartridge_type: rifle_type).count
        rescue
          0
        end}"
        puts "     * Pistol: #{begin
          CartridgeTypeBulletWeight.where(cartridge_type: pistol_type).count
        rescue
          0
        end}"
        puts "   - Manufacturers:"
        puts "     * Rifle: #{begin
          CartridgeTypeManufacturer.where(cartridge_type: rifle_type).count
        rescue
          0
        end}"
        puts "     * Pistol: #{begin
          CartridgeTypeManufacturer.where(cartridge_type: pistol_type).count
        rescue
          0
        end}"
        puts "   - Powders:"
        puts "     * Rifle: #{begin
          CartridgeTypePowder.where(cartridge_type: rifle_type).count
        rescue
          0
        end}"
        puts "     * Pistol: #{begin
          CartridgeTypePowder.where(cartridge_type: pistol_type).count
        rescue
          0
        end}"

        puts "\n📊 Total Records:"
        puts "   - Cartridges: #{Cartridge.count}"
        puts "   - Bullet Weights: #{BulletWeight.count}"
        puts "   - Manufacturers: #{Manufacturer.count}"
        puts "   - Powders: #{Powder.count}"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      end
    end
  end
end

# Helper methods for migration

def migrate_cartridges_to_associations(cartridge_type)
  puts "🔫 Migrating cartridges to associations..."

  cartridges = Cartridge.all
  migrated_count = 0

  cartridges.each do |cartridge|
    association = CartridgeTypeCartridge.find_or_create_by(
      cartridge_type: cartridge_type,
      cartridge: cartridge
    )

    if association.previously_new_record?
      migrated_count += 1
      puts "   ✓ Associated: #{cartridge.name}"
    else
      puts "   - Already associated: #{cartridge.name}"
    end
  end

  puts "   📊 Migrated #{migrated_count} cartridges"
  migrated_count
end

def migrate_bullet_weights_to_associations(cartridge_type)
  puts "⚖️  Migrating bullet weights to associations..."

  bullet_weights = BulletWeight.all
  migrated_count = 0

  bullet_weights.each do |bullet_weight|
    association = CartridgeTypeBulletWeight.find_or_create_by(
      cartridge_type: cartridge_type,
      bullet_weight: bullet_weight
    )

    if association.previously_new_record?
      migrated_count += 1
      puts "   ✓ Associated: #{bullet_weight.weight}gr"
    else
      puts "   - Already associated: #{bullet_weight.weight}gr"
    end
  end

  puts "   📊 Migrated #{migrated_count} bullet weights"
  migrated_count
end

def migrate_manufacturers_to_associations(cartridge_type)
  puts "🏭 Migrating manufacturers to associations..."

  # Only migrate powder manufacturers
  powder_type = ManufacturerType.find_by(name: "Powder")
  manufacturers = Manufacturer.where(manufacturer_type: powder_type)
  migrated_count = 0

  manufacturers.each do |manufacturer|
    association = CartridgeTypeManufacturer.find_or_create_by(
      cartridge_type: cartridge_type,
      manufacturer: manufacturer
    )

    if association.previously_new_record?
      migrated_count += 1
      puts "   ✓ Associated: #{manufacturer.name}"
    else
      puts "   - Already associated: #{manufacturer.name}"
    end
  end

  puts "   📊 Migrated #{migrated_count} manufacturers"
  migrated_count
end

def migrate_powders_to_associations(cartridge_type)
  puts "💥 Migrating powders to associations..."

  powders = Powder.all
  migrated_count = 0

  powders.each do |powder|
    association = CartridgeTypePowder.find_or_create_by(
      cartridge_type: cartridge_type,
      powder: powder
    )

    if association.previously_new_record?
      migrated_count += 1
      puts "   ✓ Associated: #{powder.name}"
    else
      puts "   - Already associated: #{powder.name}"
    end
  end

  puts "   📊 Migrated #{migrated_count} powders"
  migrated_count
end
