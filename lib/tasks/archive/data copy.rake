namespace :rp_old do
  desc "Import bullet data from Shootforum"
  task bullet_import: :environment do
    mechanize = Mechanize.new

    manufacturer_type = ManufacturerType.find_or_create_by(name: "Bullet")

    page = mechanize.get("http://www.shootforum.com/bulletdb/bullets.php")
    form = page.form
    select_list = form.field_with(name: "cal")

    # this will iterate over all of the bullet diameters
    select_list.options.each do |option|
      puts "Processing...#{option.text}"
      page = mechanize.get("http://www.shootforum.com/bulletdb/bullets.php?cal=#{option.text}")
      row_count = 0

      # (Element:0x16738 { name = "td", children = [ #(Text "0.172")] }),
      # (Element:0x250a8 { name = "td", children = [ #(Text "Berger")] }),
      # (Element:0x25288 { name = "td", children = [ #(Text "M")] }),
      # (Element:0x25468 { name = "td", children = [ #(Text "15")] }),
      # (Element:0x25648 { name = "td", children = [ #(Text "15")] }),
      # (Element:0x25828 { name = "td", children = [ #(Text "0.469")] }),
      # (Element:0x25a08 { name = "td", children = [ #(Text "0.072")] }),
      # (Element:0x25be8 { name = "td", children = [ #(Text "0.082")] }),
      # (Element:0x25dc8 { name = "td", children = [ #(Text "0.082")] }),
      # (Element:0x25fa8 { name = "td", children = [ #(Text "0.082")] }),
      # (Element:0x26188 { name = "td", children = [ #(Text "0.082")] }),
      # (Element:0x26368 { name = "td", children = [ #(Text "0.082")] }),
      # (Element:0x26548 { name = "td", children = [ #(Text "0")] }),
      # (Element:0x26728 { name = "td", children = [ #(Text "0")] }),
      # (Element:0x26908 { name = "td", children = [ #(Text "0")] }),
      # (Element:0x26ae8 { name = "td", children = [ #(Text "0")] })]

      page.search("tr").each do |row|
        if row_count.positive?
          row_data = []
          row.search("td").each do |col|
            row_data << col.text
          end

          caliber = Caliber.find_or_create_by(name: row_data[0], value: row_data[0].to_f)
          manufacturer = Manufacturer.find_or_create_by(name: row_data[1], manufacturer_type_id: manufacturer_type.id)

          Bullet.find_or_create_by(name: row_data[2], caliber:, manufacturer:,
            weight: row_data[3].to_f, bc: row_data[7].to_f, sd: row_data[6].to_f,
            length: row_data[5].to_f)
        end

        row_count += 1
      end
    end
  end
end
