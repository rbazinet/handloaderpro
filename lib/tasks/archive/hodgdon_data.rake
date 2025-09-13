# frozen_string_literal: true

namespace :hodgdon do
  desc "Import data from Hodgdon reloading website"
  task data: :environment do
    require "selenium-webdriver"
    require "nokogiri"
    puts "Starting Hodgdon data import..."

    # Setup Selenium WebDriver
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    driver = Selenium::WebDriver.for(:chrome, options: options)

    begin
      # Navigate to Hodgdon RLDC page
      puts "Loading Hodgdon RLDC page..."
      driver.get("https://hodgdonreloading.com/rldc/?t=1")

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
      puts "Waiting for page to load..."
      sleep(5) # Initial wait for JavaScript to initialize

      # Process filter_header1 (Rifle cartridges)
      process_filter_header1(driver, wait)

      # Process filter_header2 (Bullet Weights)
      process_filter_header2(driver, wait)

      # Process filter_header3 (Manufacturers - Powder type)
      process_filter_header3(driver, wait)

      # Process filter_header4 (Powders)
      process_filter_header4(driver, wait)

      puts "Hodgdon data import completed!"
    rescue => e
      puts "Error during import: #{e.message}"
      puts e.backtrace
    ensure
      driver&.quit
    end
  end

  private

  def process_filter_header1(driver, wait)
    puts "Processing filter_header1 (Rifle cartridges)..."

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
      puts "Found #{cartridge_elements.count} rifle cartridges"

      # Ensure CartridgeType exists for Rifle
      rifle_type = CartridgeType.find_or_create_by(name: "Rifle")

      # Process each cartridge
      cartridge_elements.each_with_index do |cartridge_element, index|
        cartridge_name = cartridge_element.text.strip
        next if cartridge_name.empty?

        puts "Processing cartridge #{index + 1}/#{cartridge_elements.count}: #{cartridge_name}"

        # Create or find the cartridge record
        cartridge = Cartridge.find_or_create_by(
          name: cartridge_name,
          cartridge_type: rifle_type
        )

        puts "  → Created/found cartridge: #{cartridge.name}"
      rescue => e
        puts "  → Error processing cartridge '#{cartridge_name}': #{e.message}"
        next
      end
    rescue Selenium::WebDriver::Error::TimeoutError
      puts "Timeout waiting for filter-cartridges to load"
    rescue => e
      puts "Error in process_filter_header1: #{e.message}"
    end
  end

  def process_filter_header2(driver, wait)
    puts "Processing filter_header2 (Bullet Weights)..."

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
      puts "Found #{bullet_weight_elements.count} bullet weights"

      # Use cartridge_id = 1 as specified
      cartridge = Cartridge.find_by(id: 1)
      if cartridge.nil?
        puts "  → Warning: Cartridge with ID 1 not found, using first available cartridge"
        cartridge = Cartridge.first
      end

      unless cartridge
        puts "  → Error: No cartridges available, skipping bullet weight processing"
        return
      end

      puts "  → Using cartridge: #{cartridge.name}"

      # Process each bullet weight
      bullet_weight_elements.each_with_index do |weight_element, index|
        weight_text = weight_element.text.strip
        next if weight_text.empty?

        # Extract numeric weight (handle formats like "55 gr", "150", etc.)
        weight_value = weight_text.gsub(/[^\d.]/, "").to_f
        next if weight_value.zero?

        puts "Processing bullet weight #{index + 1}/#{bullet_weight_elements.count}: #{weight_text} (#{weight_value} gr)"

        # Create or find the bullet weight record
        bullet_weight = BulletWeight.find_or_create_by(
          weight: weight_value,
          cartridge: cartridge
        )

        puts "  → Created/found bullet weight: #{bullet_weight.weight} gr"
      rescue => e
        puts "  → Error processing bullet weight '#{weight_text}': #{e.message}"
        next
      end
    rescue Selenium::WebDriver::Error::TimeoutError
      puts "Timeout waiting for filter-bulletweights to load"
    rescue => e
      puts "Error in process_filter_header2: #{e.message}"
    end
  end

  def process_filter_header3(driver, wait)
    puts "Processing filter_header3 (Manufacturers - Powder type)..."

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
      puts "Found filter-manufacturers text: #{filter_manufacturers_text}"

      # Extract manufacturer names from concatenated text
      # Known manufacturers from Hodgdon data: Accurate, Hodgdon, IMR, Ramshot, Winchester
      known_manufacturers = %w[Accurate Hodgdon IMR Ramshot Winchester]
      manufacturer_names = []

      known_manufacturers.each do |name|
        if filter_manufacturers_text.include?(name)
          manufacturer_names << name
        end
      end

      puts "Extracted #{manufacturer_names.count} manufacturer names: #{manufacturer_names.join(", ")}"

      # Find or create ManufacturerType for "Powder"
      powder_type = ManufacturerType.find_or_create_by(name: "Powder")
      puts "  → Using manufacturer type: #{powder_type.name}"

      # Process each manufacturer name
      manufacturer_names.each_with_index do |manufacturer_name, index|
        puts "Processing manufacturer #{index + 1}/#{manufacturer_names.count}: #{manufacturer_name}"

        # Check if manufacturer already exists (skip if found)
        existing_manufacturer = Manufacturer.find_by(name: manufacturer_name)
        if existing_manufacturer
          puts "  → Skipping existing manufacturer: #{manufacturer_name}"
          next
        end

        # Create the manufacturer record
        manufacturer = Manufacturer.create!(
          name: manufacturer_name,
          manufacturer_type: powder_type
        )

        puts "  → Created new manufacturer: #{manufacturer.name}"
      rescue => e
        puts "  → Error processing manufacturer '#{manufacturer_name}': #{e.message}"
        next
      end
    rescue Selenium::WebDriver::Error::TimeoutError
      puts "Timeout waiting for filter_header3 to load"
    rescue => e
      puts "Error in process_filter_header3: #{e.message}"
    end
  end

  def process_filter_header4(driver, wait)
    puts "Processing filter_header4 (Powders)..."

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
      puts "Found filter-powders text with #{filter_powders_text.length} characters"

      # Extract powder names from concatenated text
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
      powder_names = powder_names.uniq.reject(&:empty?)
      puts "Extracted #{powder_names.count} powder names"

      # Use manufacturer_id = 1 as specified
      manufacturer = Manufacturer.find_by(id: 1)
      if manufacturer.nil?
        puts "  → Warning: Manufacturer with ID 1 not found, using first available manufacturer"
        manufacturer = Manufacturer.first
      end

      unless manufacturer
        puts "  → Error: No manufacturers available, skipping powder processing"
        return
      end

      puts "  → Using manufacturer: #{manufacturer.name}"

      # Process each powder name
      powder_names.each_with_index do |powder_name, index|
        puts "Processing powder #{index + 1}/#{powder_names.count}: #{powder_name}"

        # Check if powder already exists (skip if found)
        existing_powder = Powder.find_by(name: powder_name)
        if existing_powder
          puts "  → Skipping existing powder: #{powder_name}"
          next
        end

        # Create the powder record
        powder = Powder.create!(
          name: powder_name,
          manufacturer: manufacturer
        )

        puts "  → Created new powder: #{powder.name}"
      rescue => e
        puts "  → Error processing powder '#{powder_name}': #{e.message}"
        next
      end
    rescue Selenium::WebDriver::Error::TimeoutError
      puts "Timeout waiting for filter_header4 to load"
    rescue => e
      puts "Error in process_filter_header4: #{e.message}"
    end
  end
end
