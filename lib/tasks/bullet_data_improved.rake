# frozen_string_literal: true

namespace :handloaderpro do
  namespace :bullet_data do
    desc "Fetch bullet data from JBM Ballistics and save to seed files"
    task :fetch, [:strategy] => :environment do |task, args|
      require "mechanize"
      require "json"
      require "yaml"

      # Parse strategy argument
      strategy = args[:strategy] || "replace"
      valid_strategies = %w[replace backup incremental]

      unless valid_strategies.include?(strategy)
        puts "❌ Invalid strategy '#{strategy}'. Valid options: #{valid_strategies.join(", ")}"
        exit 1
      end

      puts "🔍 Fetching bullet data from JBM Ballistics..."
      puts "📋 Strategy: #{strategy.upcase}"
      puts "=" * 60

      # Create data directory if it doesn't exist
      data_dir = Rails.root.join("db", "seeds", "bullet_data")
      FileUtils.mkdir_p(data_dir)

      # Handle different strategies
      case strategy
      when "backup"
        backup_existing_data(data_dir)
      when "incremental"
        # For incremental, we'll merge with existing data
        existing_data = load_existing_data_if_present(data_dir)
      end

      mechanize = Mechanize.new
      mechanize.user_agent_alias = "Mac Safari"

      begin
        # Fetch the main page with manufacturer list
        main_url = "https://jbmballistics.com/ballistics/lengths/lengths.shtml"
        puts "📡 Fetching from: #{main_url}"

        page = mechanize.get(main_url)

        # Extract manufacturer data
        manufacturers_data = extract_manufacturers_data(page)

        # Extract bullet data
        bullets_data = extract_bullets_data(page, manufacturers_data)

        # Handle incremental strategy
        if strategy == "incremental" && existing_data
          manufacturers_data = merge_data(manufacturers_data, existing_data[:manufacturers], "name")
          bullets_data = merge_data(bullets_data, existing_data[:bullets], "name")
        end

        # Save raw data to files
        save_fetch_metadata(data_dir, main_url, manufacturers_data, bullets_data)
        save_manufacturers_data(data_dir, manufacturers_data)
        save_bullets_data(data_dir, bullets_data)

        puts "\n✅ Data fetch completed successfully!"
        puts "📁 Data saved to: #{data_dir}"
        puts "📊 Summary:"
        puts "   - #{manufacturers_data.count} manufacturers"
        puts "   - #{bullets_data.count} bullets"
        puts "\n💡 Next step: Run 'rails handloaderpro:bullet_data:import' to import the data"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      end
    end

    desc "Import bullet data from seed files into database"
    task import: :environment do
      puts "📥 Importing bullet data from seed files..."
      puts "=" * 60

      data_dir = Rails.root.join("db", "seeds", "bullet_data")

      unless Dir.exist?(data_dir)
        puts "❌ No seed data found. Run 'rails handloaderpro:bullet_data:fetch' first."
        exit 1
      end

      begin
        # Load and validate seed data
        metadata = load_fetch_metadata(data_dir)
        manufacturers_data = load_manufacturers_data(data_dir)
        bullets_data = load_bullets_data(data_dir)

        puts "📋 Import Summary:"
        puts "   - Fetch date: #{metadata["fetch_date"]}"
        puts "   - Source: #{metadata["source_url"]}"
        puts "   - #{manufacturers_data.count} manufacturers to process"
        puts "   - #{bullets_data.count} bullets to process"
        puts ""

        # Import manufacturers
        manufacturers_created = import_manufacturers(manufacturers_data)

        # Import bullets
        bullets_created = import_bullets(bullets_data)

        puts "\n✅ Import completed successfully!"
        puts "📊 Results:"
        puts "   - #{manufacturers_created} manufacturers created/updated"
        puts "   - #{bullets_created} bullets created/updated"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      end
    end

    desc "Clean and validate bullet data files"
    task clean: :environment do
      puts "🧹 Cleaning and validating bullet data..."
      puts "=" * 60

      data_dir = Rails.root.join("db", "seeds", "bullet_data")

      unless Dir.exist?(data_dir)
        puts "❌ No seed data found. Run 'rails handloaderpro:bullet_data:fetch' first."
        exit 1
      end

      begin
        manufacturers_data = load_manufacturers_data(data_dir)
        bullets_data = load_bullets_data(data_dir)

        # Clean and validate data
        cleaned_manufacturers = clean_manufacturers_data(manufacturers_data)
        cleaned_bullets = clean_bullets_data(bullets_data)

        # Save cleaned data
        save_manufacturers_data(data_dir, cleaned_manufacturers, "_cleaned")
        save_bullets_data(data_dir, cleaned_bullets, "_cleaned")

        puts "✅ Data cleaning completed!"
        puts "📊 Results:"
        puts "   - #{cleaned_manufacturers.count} cleaned manufacturers"
        puts "   - #{cleaned_bullets.count} cleaned bullets"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      end
    end

    desc "Show bullet data statistics"
    task stats: :environment do
      puts "📊 Bullet Data Statistics"
      puts "=" * 60

      data_dir = Rails.root.join("db", "seeds", "bullet_data")

      unless Dir.exist?(data_dir)
        puts "❌ No seed data found. Run 'rails handloaderpro:bullet_data:fetch' first."
        exit 1
      end

      begin
        metadata = load_fetch_metadata(data_dir)
        manufacturers_data = load_manufacturers_data(data_dir)
        bullets_data = load_bullets_data(data_dir)

        puts "📅 Fetch Information:"
        puts "   - Date: #{metadata["fetch_date"]}"
        puts "   - Source: #{metadata["source_url"]}"
        puts "   - Duration: #{metadata["fetch_duration"]}s"
        puts ""

        puts "🏭 Manufacturers (#{manufacturers_data.count}):"
        manufacturers_data.each do |manufacturer|
          puts "   - #{manufacturer["name"]}"
        end
        puts ""

        puts "🔫 Bullets (#{bullets_data.count}):"
        caliber_stats = bullets_data.group_by { |b| b["caliber"] }
        caliber_stats.each do |caliber, bullets|
          puts "   - #{caliber}: #{bullets.count} bullets"
        end

        puts "\n📈 Database Status:"
        puts "   - Manufacturers in DB: #{Manufacturer.where(manufacturer_type: ManufacturerType.find_by(name: "Bullet")).count}"
        puts "   - Bullets in DB: #{Bullet.count}"
        puts "   - Calibers in DB: #{Caliber.count}"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      end
    end
  end
end

# Helper methods for data extraction and processing

def extract_manufacturers_data(page)
  puts "🏭 Extracting manufacturer data..."

  manufacturer_links = page.search("table").first.search("a")
  manufacturers = []

  manufacturer_links.each do |link|
    name = link.text.strip
    next if name.empty?

    manufacturers << {
      "name" => name,
      "source_url" => link["href"],
      "extracted_at" => Time.current.iso8601
    }
  end

  puts "   ✓ Found #{manufacturers.count} manufacturers"
  manufacturers
end

def extract_bullets_data(page, manufacturers_data)
  puts "🔫 Extracting bullet data..."

  bullets = []
  tables = page.search("table")

  tables.each_with_index do |table, table_index|
    rows = table.search("tr")

    rows.each_with_index do |row, row_index|
      cells = row.search("td, th").map(&:text).map(&:strip)
      next if cells.empty?

      # Check if this looks like bullet data
      if cells.first&.match?(/^\d+\.\d+$/) && cells[1]&.match?(/^\d+\.?\d*$/)
        manufacturer = find_manufacturer_for_row(table, row, manufacturers_data)

        if manufacturer
          bullet_data = {
            "caliber" => cells[0],
            "weight" => cells[1].to_f,
            "name" => cells[2] || "Unknown",
            "length" => (cells[3] && cells[3].empty?) ? nil : cells[3]&.to_f,
            "tip_length" => (cells[4] && cells[4].empty?) ? nil : cells[4]&.to_f,
            "manufacturer_name" => manufacturer["name"],
            "table_index" => table_index,
            "row_index" => row_index,
            "extracted_at" => Time.current.iso8601
          }

          bullets << bullet_data
        end
      end
    end
  end

  puts "   ✓ Found #{bullets.count} bullets"
  bullets
end

def find_manufacturer_for_row(table, current_row, manufacturers_data)
  rows = table.search("tr")
  current_index = rows.index(current_row)
  return nil unless current_index

  # Look backwards from current row to find manufacturer name
  (current_index - 1).downto(0) do |i|
    row = rows[i]
    row_text = row.text.strip

    manufacturer = manufacturers_data.find { |m| m["name"] == row_text }
    return manufacturer if manufacturer
  end

  nil
end

def save_fetch_metadata(data_dir, source_url, manufacturers_data, bullets_data)
  metadata = {
    "fetch_date" => Time.current.iso8601,
    "source_url" => source_url,
    "fetch_duration" => 0, # Will be calculated if needed
    "manufacturers_count" => manufacturers_data.count,
    "bullets_count" => bullets_data.count,
    "version" => "1.0"
  }

  File.write(data_dir.join("metadata.json"), JSON.pretty_generate(metadata))
  puts "💾 Saved metadata to metadata.json"
end

def save_manufacturers_data(data_dir, manufacturers_data, suffix = "")
  filename = "manufacturers#{suffix}.json"
  File.write(data_dir.join(filename), JSON.pretty_generate(manufacturers_data))
  puts "💾 Saved #{manufacturers_data.count} manufacturers to #{filename}"
end

def save_bullets_data(data_dir, bullets_data, suffix = "")
  filename = "bullets#{suffix}.json"
  File.write(data_dir.join(filename), JSON.pretty_generate(bullets_data))
  puts "💾 Saved #{bullets_data.count} bullets to #{filename}"
end

def load_fetch_metadata(data_dir)
  JSON.parse(File.read(data_dir.join("metadata.json")))
end

def load_manufacturers_data(data_dir)
  JSON.parse(File.read(data_dir.join("manufacturers.json")))
end

def load_bullets_data(data_dir)
  JSON.parse(File.read(data_dir.join("bullets.json")))
end

def import_manufacturers(manufacturers_data)
  puts "🏭 Importing manufacturers..."

  manufacturer_type = ManufacturerType.find_or_create_by(name: "Bullet")
  created_count = 0

  manufacturers_data.each do |manufacturer_data|
    manufacturer = Manufacturer.find_or_create_by(
      name: manufacturer_data["name"],
      manufacturer_type: manufacturer_type
    )

    if manufacturer.previously_new_record?
      created_count += 1
      puts "   ✓ Created: #{manufacturer.name}"
    else
      puts "   - Exists: #{manufacturer.name}"
    end
  end

  created_count
end

def import_bullets(bullets_data)
  puts "🔫 Importing bullets..."

  manufacturer_type = ManufacturerType.find_by(name: "Bullet")
  created_count = 0

  bullets_data.each do |bullet_data|
    # Find manufacturer
    manufacturer = Manufacturer.find_by(
      name: bullet_data["manufacturer_name"],
      manufacturer_type: manufacturer_type
    )

    next unless manufacturer

    # Find or create caliber
    caliber = Caliber.find_or_create_by(
      name: bullet_data["caliber"],
      value: bullet_data["caliber"].to_f
    )

    # Create or update bullet
    bullet = Bullet.find_or_initialize_by(
      name: bullet_data["name"],
      caliber: caliber,
      manufacturer: manufacturer
    )

    is_new = bullet.new_record?

    # Update attributes
    bullet.weight = bullet_data["weight"]
    bullet.length = bullet_data["length"] if bullet_data["length"]
    bullet.tip_length = bullet_data["tip_length"] if bullet_data["tip_length"]

    if bullet.save
      if is_new
        created_count += 1
        puts "   ✓ Created: #{bullet_data["caliber"]} #{bullet_data["weight"]}gr #{bullet_data["name"]}"
      elsif bullet.previous_changes.any?
        puts "   ↻ Updated: #{bullet_data["caliber"]} #{bullet_data["weight"]}gr #{bullet_data["name"]}"
      end
    end
  end

  created_count
end

def clean_manufacturers_data(manufacturers_data)
  puts "🧹 Cleaning manufacturer data..."

  cleaned = manufacturers_data.map do |manufacturer|
    {
      "name" => manufacturer["name"].strip,
      "source_url" => manufacturer["source_url"],
      "extracted_at" => manufacturer["extracted_at"]
    }
  end.uniq { |m| m["name"] }

  puts "   ✓ Cleaned to #{cleaned.count} unique manufacturers"
  cleaned
end

def clean_bullets_data(bullets_data)
  puts "🧹 Cleaning bullet data..."

  cleaned = bullets_data.select do |bullet|
    # Remove bullets with invalid data
    bullet["weight"] > 0 &&
      bullet["caliber"].to_f > 0 &&
      !bullet["name"].strip.empty?
  end.map do |bullet|
    {
      "caliber" => bullet["caliber"],
      "weight" => bullet["weight"],
      "name" => bullet["name"].strip,
      "length" => bullet["length"],
      "tip_length" => bullet["tip_length"],
      "manufacturer_name" => bullet["manufacturer_name"],
      "extracted_at" => bullet["extracted_at"]
    }
  end

  puts "   ✓ Cleaned to #{cleaned.count} valid bullets"
  cleaned
end

# Strategy helper methods

def backup_existing_data(data_dir)
  timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
  backup_dir = data_dir.join("backups", timestamp)
  FileUtils.mkdir_p(backup_dir)

  %w[metadata.json manufacturers.json bullets.json].each do |filename|
    source_file = data_dir.join(filename)
    if File.exist?(source_file)
      FileUtils.cp(source_file, backup_dir.join(filename))
      puts "📦 Backed up #{filename} to #{backup_dir}"
    end
  end

  puts "💾 Created backup: #{backup_dir}"
end

def load_existing_data_if_present(data_dir)
  existing_data = {}

  begin
    existing_data[:manufacturers] = load_manufacturers_data(data_dir) if File.exist?(data_dir.join("manufacturers.json"))
    existing_data[:bullets] = load_bullets_data(data_dir) if File.exist?(data_dir.join("bullets.json"))

    if existing_data.any?
      puts "📂 Found existing data:"
      existing_data.each { |type, data| puts "   - #{type}: #{data.count} items" }
    end
  rescue => e
    puts "⚠️  Warning: Could not load existing data: #{e.message}"
    existing_data = {}
  end

  existing_data
end

def merge_data(new_data, existing_data, key_field)
  return new_data if existing_data.nil? || existing_data.empty?

  # Create a hash of existing data for quick lookup
  existing_hash = existing_data.index_by { |item| item[key_field] }

  # Merge new data with existing data
  merged_data = new_data.map do |new_item|
    key_value = new_item[key_field]
    existing_item = existing_hash[key_value]

    if existing_item
      # Update existing item with new data, preserving original extracted_at
      existing_item.merge(new_item).tap do |merged_item|
        # Keep the original extracted_at if it exists
        merged_item["extracted_at"] = existing_item["extracted_at"] if existing_item["extracted_at"]
        merged_item["updated_at"] = Time.current.iso8601
      end
    else
      # New item
      new_item
    end
  end

  # Add any existing items that weren't in the new data
  new_keys = new_data.map { |item| item[key_field] }.to_set
  existing_data.each do |existing_item|
    unless new_keys.include?(existing_item[key_field])
      merged_data << existing_item
    end
  end

  puts "🔄 Merged data: #{new_data.count} new, #{existing_data.count} existing, #{merged_data.count} total"
  merged_data
end
