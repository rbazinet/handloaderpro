# frozen_string_literal: true

namespace :rp do
  desc "Import bullet data from Hodgdon"
  task hodgdon_cartridge_import: :environment do
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    driver = Selenium::WebDriver.for(:chrome, options: options)

    # driver = Selenium::WebDriver.for(:chrome)
    driver.get("https://hodgdonreloading.com/rldc/?t=1")

    revealed = driver.find_element(id: "filter-cartridges")
    errors = [Selenium::WebDriver::Error::NoSuchElementError,
      Selenium::WebDriver::Error::ElementNotInteractableError]
    wait = Selenium::WebDriver::Wait.new(timeout: 60,
      interval: 0.5,
      ignore: errors)
    wait.until { revealed.displayed? }

    document = Nokogiri::HTML(driver.page_source)
    cartridges = document.css("ul#filter-cartridges li")
    cartridge_type = CartridgeType.find_or_create_by(name: "Rifle")

    # this will iterate over all of the rifle cartridges
    previous_cartridge_id = nil
    cartridges.each do |cartridge|
      retries ||= 0
      puts cartridge.text
      c = Cartridge.find_or_create_by(name: cartridge.text, cartridge_type: cartridge_type)

      wait.until do
        value = cartridge["id"][cartridge["id"].index("-") + 1...]
        # driver.find_element(:xpath, "//input[@value='b30bd1ed-e8d0-ee11-9079-0022481fbccb']")
        driver.find_element(:xpath, "//input[@value='#{value}']").click
        # debugger
        # driver.find_element(id: cartridge['id']).click
        # driver.find_element(:xpath, ".//a[@data-guntype='Pistol']").click
        driver.find_element(:xpath, "//input[@class='filter-item-checkbox cartridge selected']")
      end

      # driver.find_element(id: cartridge['id']).click
      previous_cartridge_id = cartridge["id"]

      document = Nokogiri::HTML(driver.page_source)
      bullet_weights = document.css("ul#filter-bulletweights li")
      bullet_weights.each do |bullet_weight|
        next if bullet_weight["style"] == "display: none;"

        BulletWeight.find_or_create_by(weight: bullet_weight.text.to_f, cartridge: c)
      end

      driver.find_element(id: previous_cartridge_id).click
    rescue Selenium::WebDriver::Error::TimeoutError
      # retry if (retries += 1) < 3
      # possibly log the timeout here
      next
    rescue Selenium::WebDriver::Error::NoSuchElementError
      puts "No such element #{cartridge["id"]}, #{cartridge.text}"
      retry if (retries += 1) < 3
      next
    rescue Selenium::WebDriver::Error::ElementNotInteractableError
      puts "Not found #{cartridge["id"]}, #{cartridge.text}"
      driver.find_element(id: previous_cartridge_id).click

      retry if (retries += 1) < 3
      next
    end

    wait.until do
      driver.find_element(:xpath, ".//a[@data-guntype='Pistol']").click
      driver.find_element(:xpath, "//a[@class='guntype selected']")
    end

    document = Nokogiri::HTML(driver.page_source)
    cartridges = document.css("ul#filter-cartridges li")
    cartridge_type = CartridgeType.find_or_create_by(name: "Pistol")

    # this will iterate over all of the pistol cartridges
    previous_cartridge_id = nil
    cartridges.each do |cartridge|
      retries ||= 0

      puts cartridge.text
      c = Cartridge.find_or_create_by(name: cartridge.text, cartridge_type: cartridge_type)

      wait.until do
        value = cartridge["id"][cartridge["id"].index("-") + 1...]
        driver.find_element(:xpath, "//input[@value='#{value}']").click
        driver.find_element(:xpath, "//input[@class='filter-item-checkbox cartridge selected']")
      end

      # driver.find_element(id: cartridge['id']).click
      previous_cartridge_id = cartridge["id"]

      document = Nokogiri::HTML(driver.page_source)
      bullet_weights = document.css("ul#filter-bulletweights li")
      bullet_weights.each do |bullet_weight|
        next if bullet_weight["style"] == "display: none;"

        BulletWeight.find_or_create_by(weight: bullet_weight.text.to_f, cartridge: c)
      end

      driver.find_element(id: previous_cartridge_id).click
    rescue Selenium::WebDriver::Error::TimeoutError
      # retry if (retries += 1) < 3
      # possibly log the timeout here
      next
    rescue Selenium::WebDriver::Error::NoSuchElementError
      retry if (retries += 1) < 3
      next
    rescue Selenium::WebDriver::Error::ElementNotInteractableError
      puts "Not found #{cartridge["id"]}, #{cartridge.text}"
      driver.find_element(id: previous_cartridge_id).click

      retry if (retries += 1) < 3
      next
    end

    # debugger

    # wait.until do
    #   driver.find_element(:xpath, ".//a[@data-guntype='Shotgun']").click
    #   driver.find_element(:xpath, "//a[@class='guntype selected']")
    # end

    # document = Nokogiri::HTML(driver.page_source)
    # cartridges = document.css('ul#filter-gauges li')
    # cartridge_type = CartridgeType.find_or_create_by(name: 'Shotgun')
    #
    # # this will iterate over all of the cartridges
    # cartridges.each do |cartridge|
    #   puts cartridge.text
    #   Cartridge.find_or_create_by(name: cartridge.text, cartridge_type: cartridge_type)
    # end
  ensure
    driver.quit
  end
end
