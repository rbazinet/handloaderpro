namespace :handloaderpro do
  desc "Import bullet data from Shootforum"
  task bullet_import: :environment do
    require "mechanize"

    mechanize = Mechanize.new
    mechanize.user_agent_alias = "Mac Safari"

    manufacturer_type = ManufacturerType.find_or_create_by(name: "Bullet")

    begin
      puts "Fetching bullet database from shootforum.com..."
      page = mechanize.get("http://www.shootforum.com/bulletdb/bullets.php")
    rescue => e
      puts "Error fetching main page: #{e.message}"
      puts "Please check your internet connection or if the website is accessible."
      exit
    end

    # Find the form on the page
    form = page.forms.first

    if form.nil?
      puts "No form found on the page. The website structure may have changed."
      puts "Attempting to find caliber options directly..."

      # Try to find select element directly
      select_element = page.search('select[name="cal"]').first

      if select_element.nil?
        puts "No caliber select element found. Website structure has changed."
        puts "Unable to proceed with import."
      else
        # Extract options from the select element
        options = select_element.search("option").map { |opt| opt["value"] }.compact.reject(&:empty?)

        puts "Found #{options.length} caliber options"

        options.each do |caliber_value|
          puts "Processing caliber: #{caliber_value}"
          begin
            detail_page = mechanize.get("http://www.shootforum.com/bulletdb/bullets.php?cal=#{caliber_value}")
            process_caliber_page(detail_page, manufacturer_type)
          rescue => e
            puts "Error fetching caliber #{caliber_value}: #{e.message}"
            next
          end
        end
      end
    else
      # Original form-based approach
      select_list = form.field_with(name: "cal")

      if select_list.nil?
        puts "No caliber select field found in form"
      else
        # this will iterate over all of the bullet diameters
        select_list.options.each do |option|
          puts "Processing...#{option.text}"
          begin
            detail_page = mechanize.get("http://www.shootforum.com/bulletdb/bullets.php?cal=#{option.text}")
            process_caliber_page(detail_page, manufacturer_type)
          rescue => e
            puts "Error fetching caliber #{option.text}: #{e.message}"
            next
          end
        end
      end
    end

    puts "Import complete!"
  end
end

# Helper method for processing caliber pages
def process_caliber_page(page, manufacturer_type)
  row_count = 0
  bullets_created = 0

  # Table structure from shootforum:
  # Column 0: Caliber (e.g., "0.172")
  # Column 1: Manufacturer (e.g., "Berger")
  # Column 2: Model/Name (e.g., "M")
  # Column 3: Weight (grains)
  # Column 4: ?
  # Column 5: Length
  # Column 6: Sectional Density (SD)
  # Column 7: Ballistic Coefficient (BC)
  # Columns 8-15: Additional BC values at different velocities

  page.search("tr").each do |row|
    if row_count.positive?
      row_data = []
      row.search("td").each do |col|
        row_data << col.text.strip
      end

      # Skip if we don't have enough data
      next if row_data.length < 8

      begin
        caliber = Caliber.find_or_create_by(name: row_data[0], value: row_data[0].to_f)
        manufacturer = Manufacturer.find_or_create_by(name: row_data[1], manufacturer_type_id: manufacturer_type.id)

        bullet = Bullet.find_or_create_by(
          name: row_data[2],
          caliber: caliber,
          manufacturer: manufacturer
        ) do |b|
          b.weight = row_data[3].to_f if row_data[3].present?
          b.bc = row_data[7].to_f if row_data[7].present?
          b.sd = row_data[6].to_f if row_data[6].present?
          b.length = row_data[5].to_f if row_data[5].present?
        end

        bullets_created += 1 if bullet.previously_new_record?
      rescue => e
        puts "Error processing row: #{e.message}"
        puts "Row data: #{row_data.inspect}"
      end
    end

    row_count += 1
  end

  puts "  Processed #{row_count} rows, created #{bullets_created} new bullets"
end
