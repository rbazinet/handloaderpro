# frozen_string_literal: true

namespace :handloaderpro do
  namespace :hodgdon_data do
    desc "Fetch Hodgdon data from RLDC website and save to seed files"
    task :fetch, [:cartridge_type, :strategy] => :environment do |task, args|
      require "selenium-webdriver"
      require "nokogiri"
      require "json"
      require "yaml"

      # Parse arguments
      cartridge_type = args[:cartridge_type] || "rifle"
      strategy = args[:strategy] || "replace"

      valid_strategies = %w[replace backup incremental]
      valid_cartridge_types = %w[rifle pistol]

      unless valid_strategies.include?(strategy)
        puts "❌ Invalid strategy '#{strategy}'. Valid options: #{valid_strategies.join(", ")}"
        exit 1
      end

      unless valid_cartridge_types.include?(cartridge_type)
        puts "❌ Invalid cartridge type '#{cartridge_type}'. Valid options: #{valid_cartridge_types.join(", ")}"
        exit 1
      end

      puts "🔍 Fetching Hodgdon data from RLDC website..."
      puts "📋 Strategy: #{strategy.upcase}"
      puts "🔫 Cartridge Type: #{cartridge_type.upcase}"
      puts "=" * 60

      # Create data directory structure
      data_dir = Rails.root.join("db", "seeds", "hodgdon_data", cartridge_type)
      FileUtils.mkdir_p(data_dir)

      # Handle different strategies
      case strategy
      when "backup"
        backup_existing_data(data_dir)
      when "incremental"
        # For incremental, we'll merge with existing data
        existing_data = load_existing_data_if_present(data_dir)
      end

      # Setup Selenium WebDriver
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      driver = Selenium::WebDriver.for(:chrome, options: options)

      begin
        start_time = Time.current

        # Navigate to Hodgdon RLDC page based on cartridge type
        cartridge_type_id = (cartridge_type == "rifle") ? "1" : "2"
        source_url = "https://hodgdonreloading.com/rldc/?t=#{cartridge_type_id}"
        puts "📡 Fetching from: #{source_url}"
        driver.get(source_url)

        # Setup wait conditions
        wait = Selenium::WebDriver::Wait.new(
          timeout: 60,
          interval: 0.5,
          ignore: [
            Selenium::WebDriver::Error::NoSuchElementError,
            Selenium::WebDriver::Error::ElementNotInteractableError
          ]
        )

        # Wait for page to fully load
        puts "⏳ Waiting for page to load..."
        sleep(5) # Initial wait for JavaScript to initialize

        # Extract all data types
        cartridges_data = extract_cartridges_data(driver, wait, cartridge_type)
        bullet_weights_data = extract_bullet_weights_data(driver, wait, cartridge_type)
        manufacturers_data = extract_manufacturers_data(driver, wait, cartridge_type)
        powders_data = extract_powders_data(driver, wait, cartridge_type)

        # Handle incremental strategy
        if strategy == "incremental" && existing_data
          cartridges_data = merge_data(cartridges_data, existing_data[:cartridges], "name")
          bullet_weights_data = merge_data(bullet_weights_data, existing_data[:bullet_weights], "weight")
          manufacturers_data = merge_data(manufacturers_data, existing_data[:manufacturers], "name")
          powders_data = merge_data(powders_data, existing_data[:powders], "name")
        end

        fetch_duration = Time.current - start_time

        # Save raw data to files
        save_fetch_metadata(data_dir, source_url, cartridges_data, bullet_weights_data, manufacturers_data, powders_data, fetch_duration)
        save_cartridges_data(data_dir, cartridges_data)
        save_bullet_weights_data(data_dir, bullet_weights_data)
        save_manufacturers_data(data_dir, manufacturers_data)
        save_powders_data(data_dir, powders_data)

        puts "\n✅ Data fetch completed successfully!"
        puts "📁 Data saved to: #{data_dir}"
        puts "⏱️  Fetch duration: #{fetch_duration.round(2)}s"
        puts "📊 Summary:"
        puts "   - #{cartridges_data.count} cartridges"
        puts "   - #{bullet_weights_data.count} bullet weights"
        puts "   - #{manufacturers_data.count} manufacturers"
        puts "   - #{powders_data.count} powders"
        puts "\n💡 Next step: Run 'rails handloaderpro:hodgdon_data:import' to import the data"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      ensure
        driver&.quit
      end
    end

    desc "Import Hodgdon data from seed files into database"
    task :import, [:cartridge_type] => :environment do |task, args|
      # Parse cartridge type argument
      cartridge_type = args[:cartridge_type] || "rifle"
      valid_cartridge_types = %w[rifle pistol]

      unless valid_cartridge_types.include?(cartridge_type)
        puts "❌ Invalid cartridge type '#{cartridge_type}'. Valid options: #{valid_cartridge_types.join(", ")}"
        exit 1
      end

      puts "📥 Importing Hodgdon data from seed files..."
      puts "🔫 Cartridge Type: #{cartridge_type.upcase}"
      puts "=" * 60

      data_dir = Rails.root.join("db", "seeds", "hodgdon_data", cartridge_type)

      unless Dir.exist?(data_dir)
        puts "❌ No seed data found for #{cartridge_type}. Run 'rails handloaderpro:hodgdon_data:fetch[#{cartridge_type}]' first."
        exit 1
      end

      begin
        # Load and validate seed data
        metadata = load_fetch_metadata(data_dir)
        cartridges_data = load_cartridges_data(data_dir)
        bullet_weights_data = load_bullet_weights_data(data_dir)
        manufacturers_data = load_manufacturers_data(data_dir)
        powders_data = load_powders_data(data_dir)

        puts "📋 Import Summary:"
        puts "   - Fetch date: #{metadata["fetch_date"]}"
        puts "   - Source: #{metadata["source_url"]}"
        puts "   - #{cartridges_data.count} cartridges to process"
        puts "   - #{bullet_weights_data.count} bullet weights to process"
        puts "   - #{manufacturers_data.count} manufacturers to process"
        puts "   - #{powders_data.count} powders to process"
        puts ""

        # Import in dependency order
        cartridges_created = import_cartridges(cartridges_data, cartridge_type)
        manufacturers_created = import_manufacturers(manufacturers_data, cartridge_type)
        bullet_weights_created = import_bullet_weights(bullet_weights_data, cartridge_type)
        powders_created = import_powders(powders_data, cartridge_type)

        puts "\n✅ Import completed successfully!"
        puts "📊 Results:"
        puts "   - #{cartridges_created} cartridges created/updated"
        puts "   - #{manufacturers_created} manufacturers created/updated"
        puts "   - #{bullet_weights_created} bullet weights created/updated"
        puts "   - #{powders_created} powders created/updated"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      end
    end

    desc "Clean and validate Hodgdon data files"
    task clean: :environment do
      puts "🧹 Cleaning and validating Hodgdon data..."
      puts "=" * 60

      data_dir = Rails.root.join("db", "seeds", "hodgdon_data")

      unless Dir.exist?(data_dir)
        puts "❌ No seed data found. Run 'rails handloaderpro:hodgdon_data:fetch' first."
        exit 1
      end

      begin
        cartridges_data = load_cartridges_data(data_dir)
        bullet_weights_data = load_bullet_weights_data(data_dir)
        manufacturers_data = load_manufacturers_data(data_dir)
        powders_data = load_powders_data(data_dir)

        # Clean and validate data
        cleaned_cartridges = clean_cartridges_data(cartridges_data)
        cleaned_bullet_weights = clean_bullet_weights_data(bullet_weights_data)
        cleaned_manufacturers = clean_manufacturers_data(manufacturers_data)
        cleaned_powders = clean_powders_data(powders_data)

        # Save cleaned data
        save_cartridges_data(data_dir, cleaned_cartridges, "_cleaned")
        save_bullet_weights_data(data_dir, cleaned_bullet_weights, "_cleaned")
        save_manufacturers_data(data_dir, cleaned_manufacturers, "_cleaned")
        save_powders_data(data_dir, cleaned_powders, "_cleaned")

        puts "✅ Data cleaning completed!"
        puts "📊 Results:"
        puts "   - #{cleaned_cartridges.count} cleaned cartridges"
        puts "   - #{cleaned_bullet_weights.count} cleaned bullet weights"
        puts "   - #{cleaned_manufacturers.count} cleaned manufacturers"
        puts "   - #{cleaned_powders.count} cleaned powders"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      end
    end

    desc "Show Hodgdon data statistics"
    task stats: :environment do
      puts "📊 Hodgdon Data Statistics"
      puts "=" * 60

      data_dir = Rails.root.join("db", "seeds", "hodgdon_data")

      unless Dir.exist?(data_dir)
        puts "❌ No seed data found. Run 'rails handloaderpro:hodgdon_data:fetch' first."
        exit 1
      end

      begin
        metadata = load_fetch_metadata(data_dir)
        cartridges_data = load_cartridges_data(data_dir)
        bullet_weights_data = load_bullet_weights_data(data_dir)
        manufacturers_data = load_manufacturers_data(data_dir)
        powders_data = load_powders_data(data_dir)

        puts "📅 Fetch Information:"
        puts "   - Date: #{metadata["fetch_date"]}"
        puts "   - Source: #{metadata["source_url"]}"
        puts "   - Duration: #{metadata["fetch_duration"]}s"
        puts ""

        puts "🔫 Cartridges (#{cartridges_data.count}):"
        cartridges_data.first(10).each do |cartridge|
          puts "   - #{cartridge["name"]}"
        end
        puts "   ... and #{cartridges_data.count - 10} more" if cartridges_data.count > 10
        puts ""

        puts "⚖️  Bullet Weights (#{bullet_weights_data.count}):"
        weight_ranges = bullet_weights_data.group_by { |bw| (bw["weight"] / 50).floor * 50 }
        weight_ranges.sort.each do |range, weights|
          puts "   - #{range}-#{range + 49}gr: #{weights.count} weights"
        end
        puts ""

        puts "🏭 Manufacturers (#{manufacturers_data.count}):"
        manufacturers_data.each do |manufacturer|
          puts "   - #{manufacturer["name"]}"
        end
        puts ""

        puts "💥 Powders (#{powders_data.count}):"
        powder_categories = powders_data.group_by { |p| categorize_powder(p["name"]) }
        powder_categories.each do |category, powders|
          puts "   - #{category}: #{powders.count} powders"
        end

        puts "\n📈 Database Status:"
        puts "   - Cartridges in DB: #{Cartridge.count}"
        puts "   - Bullet Weights in DB: #{BulletWeight.count}"
        puts "   - Manufacturers in DB: #{Manufacturer.where(manufacturer_type: ManufacturerType.find_by(name: "Powder")).count}"
        puts "   - Powders in DB: #{Powder.count}"
      rescue => e
        puts "❌ FATAL ERROR: #{e.message}"
        puts e.backtrace.first(5)
        exit 1
      end
    end
  end
end

# Helper methods for data extraction and processing

def extract_cartridges_data(driver, wait, cartridge_type)
  puts "🔫 Extracting cartridge data..."

  begin
    # Wait for the filter-cartridges element to be visible
    wait.until do
      element = driver.find_element(id: "filter-cartridges")
      element.displayed?
    end

    # Get the page source and parse with Nokogiri
    document = Nokogiri::HTML(driver.page_source)

    # Find all cartridge checkboxes under filter_header1
    cartridge_elements = document.css("ul#filter-cartridges li")
    cartridges = []

    cartridge_elements.each do |cartridge_element|
      name = cartridge_element.text.strip
      next if name.empty?

      cartridges << {
        "name" => name,
        "cartridge_type" => cartridge_type.capitalize,
        "cartridge_type_id" => (cartridge_type == "rifle") ? 1 : 2,
        "extracted_at" => Time.current.iso8601
      }
    end

    puts "   ✓ Found #{cartridges.count} cartridges"
    cartridges
  rescue Selenium::WebDriver::Error::TimeoutError
    puts "   ⚠️ Timeout waiting for filter-cartridges to load"
    []
  rescue => e
    puts "   ⚠️ Error extracting cartridges: #{e.message}"
    []
  end
end

def extract_bullet_weights_data(driver, wait, cartridge_type)
  puts "⚖️  Extracting bullet weight data..."

  begin
    # Wait for the filter-bulletweights element to be visible
    wait.until do
      element = driver.find_element(id: "filter-bulletweights")
      element.displayed?
    end

    # Get the page source and parse with Nokogiri
    document = Nokogiri::HTML(driver.page_source)

    # Find all bullet weight elements under filter_header2
    bullet_weight_elements = document.css("ul#filter-bulletweights li")
    bullet_weights = []

    bullet_weight_elements.each do |weight_element|
      weight_text = weight_element.text.strip
      next if weight_text.empty?

      # Extract numeric weight (handle formats like "55 gr", "150", etc.)
      weight_value = weight_text.gsub(/[^\d.]/, "").to_f
      next if weight_value.zero?

      bullet_weights << {
        "weight" => weight_value,
        "weight_text" => weight_text,
        "cartridge_type" => cartridge_type.capitalize,
        "cartridge_type_id" => (cartridge_type == "rifle") ? 1 : 2,
        "extracted_at" => Time.current.iso8601
      }
    end

    puts "   ✓ Found #{bullet_weights.count} bullet weights"
    bullet_weights
  rescue Selenium::WebDriver::Error::TimeoutError
    puts "   ⚠️ Timeout waiting for filter-bulletweights to load"
    []
  rescue => e
    puts "   ⚠️ Error extracting bullet weights: #{e.message}"
    []
  end
end

def extract_manufacturers_data(driver, wait, cartridge_type)
  puts "🏭 Extracting manufacturer data..."

  begin
    # Wait for the filter_header3 element to be visible
    wait.until do
      element = driver.find_element(id: "filter_header3")
      element.displayed?
    end

    # Get the page source and parse with Nokogiri
    document = Nokogiri::HTML(driver.page_source)

    # Get manufacturer names from the concatenated text in filter-manufacturers
    filter_manufacturers_text = document.css("#filter-manufacturers").first&.text&.strip || ""

    # Extract manufacturer names from concatenated text
    # Known manufacturers from Hodgdon data: Accurate, Hodgdon, IMR, Ramshot, Winchester
    known_manufacturers = %w[Accurate Hodgdon IMR Ramshot Winchester]
    manufacturers = []

    known_manufacturers.each do |name|
      if filter_manufacturers_text.include?(name)
        manufacturers << {
          "name" => name,
          "manufacturer_type" => "Powder",
          "cartridge_type" => cartridge_type.capitalize,
          "cartridge_type_id" => (cartridge_type == "rifle") ? 1 : 2,
          "source_text" => filter_manufacturers_text,
          "extracted_at" => Time.current.iso8601
        }
      end
    end

    puts "   ✓ Found #{manufacturers.count} manufacturers"
    manufacturers
  rescue Selenium::WebDriver::Error::TimeoutError
    puts "   ⚠️ Timeout waiting for filter_header3 to load"
    []
  rescue => e
    puts "   ⚠️ Error extracting manufacturers: #{e.message}"
    []
  end
end

def extract_powders_data(driver, wait, cartridge_type)
  puts "💥 Extracting powder data..."

  begin
    # Wait for the filter_header4 element to be visible
    wait.until do
      element = driver.find_element(id: "filter_header4")
      element.displayed?
    end

    # Get the page source and parse with Nokogiri
    document = Nokogiri::HTML(driver.page_source)

    # Get powder names from the concatenated text in filter-powders
    filter_powders_text = document.css("#filter-powders").first&.text&.strip || ""

    # Extract powder names from concatenated text
    powder_names = extract_powder_names(filter_powders_text)

    powders = powder_names.map do |powder_name|
      {
        "name" => powder_name,
        "manufacturer_name" => determine_powder_manufacturer(powder_name),
        "cartridge_type" => cartridge_type.capitalize,
        "cartridge_type_id" => (cartridge_type == "rifle") ? 1 : 2,
        "source_text" => filter_powders_text,
        "extracted_at" => Time.current.iso8601
      }
    end

    puts "   ✓ Found #{powders.count} powders"
    powders
  rescue Selenium::WebDriver::Error::TimeoutError
    puts "   ⚠️ Timeout waiting for filter_header4 to load"
    []
  rescue => e
    puts "   ⚠️ Error extracting powders: #{e.message}"
    []
  end
end

def extract_powder_names(filter_powders_text)
  # Remove leading numbers
  clean_text = filter_powders_text.gsub(/^\d+/, "")

  powder_names = []

  # Extract H-series powders (H1000, H110, etc.) - they're concatenated
  h_powders = clean_text.scan(/(H\d+(?:SC|BMG)?)/i)
  powder_names.concat(h_powders.flatten)

  # Extract IMR powders (IMR 3031, IMR 4064, etc.)
  imr_powders = clean_text.scan(/(IMR \d+(?:\s+[A-Z]+)?)/i)
  powder_names.concat(imr_powders.flatten)

  # Extract SR powders
  sr_powders = clean_text.scan(/(SR \d+)/i)
  powder_names.concat(sr_powders.flatten)

  # Extract StaBALL variants
  staball_powders = clean_text.scan(/(StaBALL[^A-Z]*(?:[A-Z]*))/i)
  powder_names.concat(staball_powders.flatten)

  # Extract CFE variants
  cfe_powders = clean_text.scan(/(CFE\s+[A-Z0-9]+)/i)
  powder_names.concat(cfe_powders.flatten)

  # Extract numbered powders (700-X, No. 11FS, etc.)
  numbered_powders = clean_text.scan(/(\d+-[A-Z]|No\.\s+\d+[A-Z]*)/i)
  powder_names.concat(numbered_powders.flatten)

  # Extract BL-C(2)
  if clean_text.include?("BL-C(2)")
    powder_names << "BL-C(2)"
  end

  # Manual extraction of single-word powder names
  single_word_powders = %w[
    Benchmark Clays Enforcer Grand Hunter Magnum Magpro Retumbo
    Superformance Titegroup Universal Varget Revolution
  ]

  single_word_powders.each do |name|
    if clean_text.include?(name)
      powder_names << name
    end
  end

  # Extract multi-word powder names
  multi_word_powders = [
    "Big Game", "Trail Boss", "Hybrid 100V", "LT-30", "LT-32",
    "US 869", "Supreme 780", "X-Terminator"
  ]

  multi_word_powders.each do |name|
    if clean_text.include?(name.delete(" "))
      powder_names << name
    end
  end

  # Remove duplicates and clean up
  powder_names.uniq.reject(&:empty?)
end

def determine_powder_manufacturer(powder_name)
  case powder_name
  when /^H\d+/i
    "Hodgdon"
  when /^IMR/i
    "IMR"
  when /^SR/i
    "Hodgdon"
  when /^CFE/i
    "Hodgdon"
  when /^LT-/i
    "Hodgdon"
  when /^US \d+/i
    "Hodgdon"
  when /^Supreme/i
    "Hodgdon"
  when /^X-Terminator/i
    "Hodgdon"
  else
    "Hodgdon" # Default to Hodgdon for most powders
  end
end

def categorize_powder(powder_name)
  case powder_name
  when /^H\d+/i
    "H-Series"
  when /^IMR/i
    "IMR"
  when /^SR/i
    "SR-Series"
  when /^CFE/i
    "CFE-Series"
  when /^StaBALL/i
    "StaBALL"
  when /^\d+-[A-Z]/i
    "Numbered"
  when /^No\./i
    "Numbered"
  else
    "Other"
  end
end

# Data saving methods

def save_fetch_metadata(data_dir, source_url, cartridges_data, bullet_weights_data, manufacturers_data, powders_data, fetch_duration)
  metadata = {
    "fetch_date" => Time.current.iso8601,
    "source_url" => source_url,
    "fetch_duration" => fetch_duration,
    "cartridges_count" => cartridges_data.count,
    "bullet_weights_count" => bullet_weights_data.count,
    "manufacturers_count" => manufacturers_data.count,
    "powders_count" => powders_data.count,
    "version" => "1.0"
  }

  File.write(data_dir.join("metadata.json"), JSON.pretty_generate(metadata))
  puts "💾 Saved metadata to metadata.json"
end

def save_cartridges_data(data_dir, cartridges_data, suffix = "")
  filename = "cartridges#{suffix}.json"
  File.write(data_dir.join(filename), JSON.pretty_generate(cartridges_data))
  puts "💾 Saved #{cartridges_data.count} cartridges to #{filename}"
end

def save_bullet_weights_data(data_dir, bullet_weights_data, suffix = "")
  filename = "bullet_weights#{suffix}.json"
  File.write(data_dir.join(filename), JSON.pretty_generate(bullet_weights_data))
  puts "💾 Saved #{bullet_weights_data.count} bullet weights to #{filename}"
end

def save_manufacturers_data(data_dir, manufacturers_data, suffix = "")
  filename = "manufacturers#{suffix}.json"
  File.write(data_dir.join(filename), JSON.pretty_generate(manufacturers_data))
  puts "💾 Saved #{manufacturers_data.count} manufacturers to #{filename}"
end

def save_powders_data(data_dir, powders_data, suffix = "")
  filename = "powders#{suffix}.json"
  File.write(data_dir.join(filename), JSON.pretty_generate(powders_data))
  puts "💾 Saved #{powders_data.count} powders to #{filename}"
end

# Data loading methods

def load_fetch_metadata(data_dir)
  JSON.parse(File.read(data_dir.join("metadata.json")))
end

def load_cartridges_data(data_dir)
  JSON.parse(File.read(data_dir.join("cartridges.json")))
end

def load_bullet_weights_data(data_dir)
  JSON.parse(File.read(data_dir.join("bullet_weights.json")))
end

def load_manufacturers_data(data_dir)
  JSON.parse(File.read(data_dir.join("manufacturers.json")))
end

def load_powders_data(data_dir)
  JSON.parse(File.read(data_dir.join("powders.json")))
end

# Data import methods

def import_cartridges(cartridges_data, cartridge_type)
  puts "🔫 Importing cartridges..."

  cartridge_type_record = CartridgeType.find((cartridge_type == "rifle") ? 1 : 2)
  created_count = 0

  cartridges_data.each do |cartridge_data|
    # Create or find cartridge (without cartridge_type since we'll use associations)
    cartridge = Cartridge.find_or_create_by(name: cartridge_data["name"])

    # Create association
    association = CartridgeTypeCartridge.find_or_create_by(
      cartridge_type: cartridge_type_record,
      cartridge: cartridge
    )

    if cartridge.previously_new_record?
      created_count += 1
      puts "   ✓ Created: #{cartridge.name} (#{cartridge_type.capitalize})"
    elsif association.previously_new_record?
      puts "   ↻ Associated: #{cartridge.name} (#{cartridge_type.capitalize})"
    else
      puts "   - Exists: #{cartridge.name} (#{cartridge_type.capitalize})"
    end
  end

  created_count
end

def import_bullet_weights(bullet_weights_data, cartridge_type)
  puts "⚖️  Importing bullet weights..."

  cartridge_type_record = CartridgeType.find((cartridge_type == "rifle") ? 1 : 2)
  created_count = 0

  bullet_weights_data.each do |bullet_weight_data|
    # Create or find bullet weight (without cartridge since we'll use associations)
    bullet_weight = BulletWeight.find_or_create_by(weight: bullet_weight_data["weight"])

    # Create association
    association = CartridgeTypeBulletWeight.find_or_create_by(
      cartridge_type: cartridge_type_record,
      bullet_weight: bullet_weight
    )

    if bullet_weight.previously_new_record?
      created_count += 1
      puts "   ✓ Created: #{bullet_weight.weight}gr (#{cartridge_type.capitalize})"
    elsif association.previously_new_record?
      puts "   ↻ Associated: #{bullet_weight.weight}gr (#{cartridge_type.capitalize})"
    else
      puts "   - Exists: #{bullet_weight.weight}gr (#{cartridge_type.capitalize})"
    end
  end

  created_count
end

def import_manufacturers(manufacturers_data, cartridge_type)
  puts "🏭 Importing manufacturers..."

  powder_type = ManufacturerType.find_or_create_by(name: "Powder")
  cartridge_type_record = CartridgeType.find((cartridge_type == "rifle") ? 1 : 2)
  created_count = 0

  manufacturers_data.each do |manufacturer_data|
    # Create or find manufacturer
    manufacturer = Manufacturer.find_or_create_by(
      name: manufacturer_data["name"],
      manufacturer_type: powder_type
    )

    # Create association
    association = CartridgeTypeManufacturer.find_or_create_by(
      cartridge_type: cartridge_type_record,
      manufacturer: manufacturer
    )

    if manufacturer.previously_new_record?
      created_count += 1
      puts "   ✓ Created: #{manufacturer.name} (#{cartridge_type.capitalize})"
    elsif association.previously_new_record?
      puts "   ↻ Associated: #{manufacturer.name} (#{cartridge_type.capitalize})"
    else
      puts "   - Exists: #{manufacturer.name} (#{cartridge_type.capitalize})"
    end
  end

  created_count
end

def import_powders(powders_data, cartridge_type)
  puts "💥 Importing powders..."

  powder_type = ManufacturerType.find_by(name: "Powder")
  cartridge_type_record = CartridgeType.find((cartridge_type == "rifle") ? 1 : 2)
  created_count = 0

  powders_data.each do |powder_data|
    # Find manufacturer
    manufacturer = Manufacturer.find_by(
      name: powder_data["manufacturer_name"],
      manufacturer_type: powder_type
    )

    next unless manufacturer

    # Create or update powder
    powder = Powder.find_or_create_by(
      name: powder_data["name"],
      manufacturer: manufacturer
    )

    # Create association
    association = CartridgeTypePowder.find_or_create_by(
      cartridge_type: cartridge_type_record,
      powder: powder
    )

    if powder.previously_new_record?
      created_count += 1
      puts "   ✓ Created: #{powder.name} (#{manufacturer.name}) (#{cartridge_type.capitalize})"
    elsif association.previously_new_record?
      puts "   ↻ Associated: #{powder.name} (#{manufacturer.name}) (#{cartridge_type.capitalize})"
    else
      puts "   - Exists: #{powder.name} (#{manufacturer.name}) (#{cartridge_type.capitalize})"
    end
  end

  created_count
end

# Data cleaning methods

def clean_cartridges_data(cartridges_data)
  puts "🧹 Cleaning cartridge data..."

  cleaned = cartridges_data.map do |cartridge|
    {
      "name" => cartridge["name"].strip,
      "cartridge_type" => cartridge["cartridge_type"],
      "extracted_at" => cartridge["extracted_at"]
    }
  end.uniq { |c| c["name"] }

  puts "   ✓ Cleaned to #{cleaned.count} unique cartridges"
  cleaned
end

def clean_bullet_weights_data(bullet_weights_data)
  puts "🧹 Cleaning bullet weight data..."

  cleaned = bullet_weights_data.select do |bullet_weight|
    # Remove weights with invalid data
    bullet_weight["weight"] > 0
  end.map do |bullet_weight|
    {
      "weight" => bullet_weight["weight"],
      "weight_text" => bullet_weight["weight_text"],
      "extracted_at" => bullet_weight["extracted_at"]
    }
  end.uniq { |bw| bw["weight"] }

  puts "   ✓ Cleaned to #{cleaned.count} unique bullet weights"
  cleaned
end

def clean_manufacturers_data(manufacturers_data)
  puts "🧹 Cleaning manufacturer data..."

  cleaned = manufacturers_data.map do |manufacturer|
    {
      "name" => manufacturer["name"].strip,
      "manufacturer_type" => manufacturer["manufacturer_type"],
      "extracted_at" => manufacturer["extracted_at"]
    }
  end.uniq { |m| m["name"] }

  puts "   ✓ Cleaned to #{cleaned.count} unique manufacturers"
  cleaned
end

def clean_powders_data(powders_data)
  puts "🧹 Cleaning powder data..."

  cleaned = powders_data.select do |powder|
    # Remove powders with invalid data
    !powder["name"].strip.empty?
  end.map do |powder|
    {
      "name" => powder["name"].strip,
      "manufacturer_name" => powder["manufacturer_name"],
      "extracted_at" => powder["extracted_at"]
    }
  end.uniq { |p| p["name"] }

  puts "   ✓ Cleaned to #{cleaned.count} unique powders"
  cleaned
end

# Strategy helper methods

def backup_existing_data(data_dir)
  timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
  backup_dir = data_dir.join("backups", timestamp)
  FileUtils.mkdir_p(backup_dir)

  %w[metadata.json cartridges.json bullet_weights.json manufacturers.json powders.json].each do |filename|
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
    existing_data[:cartridges] = load_cartridges_data(data_dir) if File.exist?(data_dir.join("cartridges.json"))
    existing_data[:bullet_weights] = load_bullet_weights_data(data_dir) if File.exist?(data_dir.join("bullet_weights.json"))
    existing_data[:manufacturers] = load_manufacturers_data(data_dir) if File.exist?(data_dir.join("manufacturers.json"))
    existing_data[:powders] = load_powders_data(data_dir) if File.exist?(data_dir.join("powders.json"))

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
