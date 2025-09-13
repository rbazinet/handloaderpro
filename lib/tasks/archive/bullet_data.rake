namespace :handloaderpro do
  desc "Import bullet data from JBM Ballistics"
  task bullet_data: :environment do
    require "mechanize"

    mechanize = Mechanize.new
    mechanize.user_agent_alias = "Mac Safari"

    # Find or create the ManufacturerType for "Bullet"
    manufacturer_type = ManufacturerType.find_or_create_by(name: "Bullet")
    manufacturer_type_id = manufacturer_type.id

    puts "Starting JBM Ballistics manufacturer import..."
    puts "Using ManufacturerType: '#{manufacturer_type.name}' (ID: #{manufacturer_type_id})"
    puts "=" * 60

    begin
      # Fetch the main page with manufacturer list
      main_url = "https://jbmballistics.com/ballistics/lengths/lengths.shtml"
      puts "Fetching manufacturer list from: #{main_url}"

      page = mechanize.get(main_url)

      # Find all manufacturer links in the table
      # The page has a table with manufacturer links
      manufacturer_links = page.search("table").first.search("a")

      puts "Found #{manufacturer_links.count} manufacturer links"
      puts "-" * 60

      manufacturers_created = 0
      manufacturers_existing = 0

      # First pass: Create manufacturers
      manufacturer_links.each_with_index do |link, index|
        manufacturer_name = link.text.strip

        # Skip empty names
        next if manufacturer_name.empty?

        puts "[#{index + 1}/#{manufacturer_links.count}] Processing manufacturer: #{manufacturer_name}"

        # Create or find manufacturer with required manufacturer_type_id
        manufacturer = Manufacturer.find_or_create_by(
          name: manufacturer_name,
          manufacturer_type_id: manufacturer_type_id
        )

        if manufacturer.previously_new_record?
          manufacturers_created += 1
          puts "  ✓ Created new manufacturer: #{manufacturer_name}"
        else
          manufacturers_existing += 1
          puts "  - Manufacturer already exists: #{manufacturer_name}"
        end
      end

      puts "\n" + "=" * 60
      puts "Now processing bullet data tables..."
      puts "=" * 60

      # Second pass: Parse bullet data from the page
      bullet_results = process_bullet_tables(page, manufacturer_type_id)
      bullets_created = bullet_results[:created]
      bullets_updated = bullet_results[:updated]

      puts "\n" + "=" * 60
      puts "Summary:"
      puts "  Manufacturers:"
      puts "    Created: #{manufacturers_created} new manufacturers"
      puts "    Existing: #{manufacturers_existing} manufacturers already in database"
      puts "    Total: #{manufacturers_created + manufacturers_existing} manufacturers processed"
      puts "  Bullets:"
      puts "    Created: #{bullets_created} new bullets"
      puts "    Updated: #{bullets_updated} existing bullets"
      puts "    Total: #{bullets_created + bullets_updated} bullets processed"
      puts "=" * 60
      puts "Import completed successfully!"
    rescue => e
      puts "FATAL ERROR: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end
end

def process_bullet_tables(page, manufacturer_type_id)
  bullets_created = 0
  bullets_updated = 0

  puts "Searching for bullet data using targeted approach..."

  # First, let's just try to find "0.223" which should be in the bullet data
  page_html = page.body
  if page_html.include?("0.223")
    puts "✓ Found '0.223' in page content - bullet data is present"
  else
    puts "✗ Could not find '0.223' in page content - bullet data may be missing"
    return {created: 0, updated: 0}
  end

  # Look for specific patterns that indicate bullet data
  aguila_sections = []
  lines = page_html.split(/\r?\n/)

  lines.each_with_index do |line, i|
    if line.include?("0.223") && line.include?("29.0")
      puts "🎯 Found potential Aguila bullet data at line #{i}: #{line.strip[0..100]}"
      aguila_sections << {line_num: i, content: line.strip}
    end
  end

  puts "Found #{aguila_sections.count} potential bullet data lines"

  # Try a different approach - look for table structures
  tables = page.search("table")
  puts "Found #{tables.count} HTML tables on the page"

  tables.each_with_index do |table, i|
    rows = table.search("tr")
    puts "Table #{i} has #{rows.count} rows"

    # Look for rows that contain bullet-like data
    rows.each_with_index do |row, j|
      cells = row.search("td, th").map(&:text).map(&:strip)
      next if cells.empty?

      # Check if this looks like bullet data
      if cells.first&.match?(/^\d+\.\d+$/) && cells[1]&.match?(/^\d+\.?\d*$/)
        puts "  Row #{j}: #{cells.join(" | ")}"

        # Try to process this as bullet data
        begin
          caliber_text = cells[0]
          weight_text = cells[1]
          description = cells[2] || "Unknown"
          length_text = cells[3]
          tip_length_text = cells[4]

          # Find manufacturer for this data (look backwards in the table or page)
          manufacturer = find_manufacturer_for_bullet_row(table, row, manufacturer_type_id)

          if manufacturer
            puts "    📍 Associated with manufacturer: #{manufacturer.name}"

            # Process the bullet data
            caliber_value = caliber_text.to_f
            weight = weight_text.to_f

            next if caliber_value == 0.0 || weight == 0.0

            # Find or create caliber
            caliber = Caliber.find_or_create_by(
              name: caliber_text,
              value: caliber_value
            )

            # Parse optional length values
            length = length_text&.empty? ? nil : length_text&.to_f
            length = nil if length && length == 0.0

            tip_length = tip_length_text&.empty? ? nil : tip_length_text&.to_f
            tip_length = nil if tip_length && tip_length == 0.0

            # Create or update bullet
            bullet = Bullet.find_or_initialize_by(
              name: description,
              caliber: caliber,
              manufacturer: manufacturer
            )

            is_new = bullet.new_record?

            # Update attributes
            bullet.weight = weight
            bullet.length = length if length
            bullet.tip_length = tip_length if tip_length

            if bullet.save
              if is_new
                bullets_created += 1
                puts "    ✓ Created: #{caliber_text} #{weight}gr #{description}"
              elsif bullet.previous_changes.any?
                bullets_updated += 1
                puts "    ↻ Updated: #{caliber_text} #{weight}gr #{description}"
              end
            end
          end
        rescue => e
          puts "    ⚠️ Error processing row: #{e.message}"
        end
      end
    end
  end

  {created: bullets_created, updated: bullets_updated}
end

def find_manufacturer_for_bullet_row(table, current_row, manufacturer_type_id)
  # Look for manufacturer name in previous rows of the same table
  rows = table.search("tr")
  current_index = rows.index(current_row)

  return nil unless current_index

  # Look backwards from current row to find manufacturer name
  (current_index - 1).downto(0) do |i|
    row = rows[i]
    row_text = row.text.strip

    manufacturer = Manufacturer.find_by(name: row_text, manufacturer_type_id: manufacturer_type_id)
    return manufacturer if manufacturer
  end

  nil
end
