require "application_system_test_case"

class ReloadingSessionsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @account = accounts(:one)
    sign_in @user
    switch_account(@account)
  end

  test "visiting the new reloading session form" do
    visit new_reloading_session_path
    assert_selector "h1", text: "New Reloading Session"
    assert_selector "form"
  end

  test "creating a valid reloading session with dropdown bullet weight" do
    visit new_reloading_session_path

    # Fill Session Information
    fill_in "Loaded at", with: Date.current
    fill_in "Quantity", with: "50"
    fill_in "COL (inches)", with: "2.810"
    select "Hodgdon Reloading", from: "Data Source"

    # Fill Components
    select "Lapua .308 Win", from: "Cartridge"
    select "Brass", from: "Cartridge Type"
    select "Sierra MatchKing 168gr BTHP", from: "Bullet"
    fill_in "Bullet Type", with: "Match"
    select "168.0 grains", from: "Bullet Weight"
    select "Hodgdon Varget", from: "Powder"
    fill_in "Powder Weight (gr)", with: "42.5"
    select "CCI BR2", from: "Primer"
    select "Large Rifle", from: "Primer Type"

    # Fill Notes
    fill_in "Notes", with: "Test load for accuracy"

    click_button "Create Reloading session"

    assert_text "Reloading session was successfully created"
    assert_current_path reloading_session_path(ReloadingSession.last)
  end

  test "creating a valid reloading session with custom bullet weight" do
    visit new_reloading_session_path

    # Fill Session Information
    fill_in "Loaded at", with: Date.current
    fill_in "Quantity", with: "25"
    fill_in "COL (inches)", with: "2.820"
    select "Hornady", from: "Data Source"

    # Fill Components - use custom bullet weight instead of dropdown
    select "Federal .308 Win", from: "Cartridge"
    select "Brass", from: "Cartridge Type" 
    select "Hornady A-MAX 155gr", from: "Bullet"
    fill_in "Bullet Type", with: "A-MAX"
    # Don't select from Bullet Weight dropdown
    fill_in "Custom Weight (gr)", with: "168.25"
    select "Hodgdon H4895", from: "Powder"
    fill_in "Powder Weight (gr)", with: "41.0"
    select "Federal 210", from: "Primer"
    select "Large Rifle", from: "Primer Type"

    click_button "Create Reloading session"

    assert_text "Reloading session was successfully created"
    assert_current_path reloading_session_path(ReloadingSession.last)
    
    # Verify custom weight was saved
    session = ReloadingSession.last
    assert_equal 168.25, session.bullet_weight_other.to_f
  end

  test "showing validation errors when required fields are missing" do
    visit new_reloading_session_path

    # Submit form without filling required fields
    click_button "Create Reloading session"

    # Should stay on form page with errors
    assert_selector "h1", text: "New Reloading Session"
    
    # Should show error alert at top
    assert_selector ".alert-danger"
    
    # Should show specific error messages
    assert_text "Loaded at can't be blank"
    assert_text "Cartridge must be selected"
    assert_text "Cartridge type must be selected"
    assert_text "Data source must be selected"
    assert_text "Bullet must be selected"
    assert_text "Powder must be selected"
    assert_text "Primer must be selected"
    assert_text "Primer type must be selected"
    assert_text "Bullet weight must be selected or custom weight must be entered"
  end

  test "showing validation error when neither bullet weight nor custom weight provided" do
    visit new_reloading_session_path

    # Fill all required fields except bullet weight
    fill_in "Loaded at", with: Date.current
    select "Lapua .308 Win", from: "Cartridge"
    select "Brass", from: "Cartridge Type"
    select "Hodgdon Reloading", from: "Data Source"
    select "Sierra MatchKing 168gr BTHP", from: "Bullet"
    select "Hodgdon Varget", from: "Powder"
    select "CCI BR2", from: "Primer"
    select "Large Rifle", from: "Primer Type"
    # Don't select bullet weight or enter custom weight

    click_button "Create Reloading session"

    assert_selector ".alert-danger"
    assert_text "Bullet weight must be selected or custom weight must be entered"
  end

  test "quantity field accepts only whole numbers" do
    visit new_reloading_session_path
    
    quantity_field = find_field("Quantity")
    assert_equal "1", quantity_field["step"]
  end

  test "custom weight field accepts decimals" do
    visit new_reloading_session_path
    
    custom_weight_field = find_field("Custom Weight (gr)")
    assert_equal "0.01", custom_weight_field["step"]
  end

  test "custom data source field appears when Other is selected" do
    visit new_reloading_session_path
    
    # Custom field should be hidden initially
    assert_not find_field("Custom Data Source Name", visible: false).visible?
    
    # Select "Other" from Data Source dropdown
    select "Other", from: "Data Source"
    
    # Custom field should become visible
    assert find_field("Custom Data Source Name").visible?
  end

  test "loaded at field shows error styling but no inline message" do
    visit new_reloading_session_path
    
    # Submit form to trigger validation errors
    click_button "Create Reloading session"
    
    # Should show error in alert at top
    assert_selector ".alert-danger"
    assert_text "Loaded at can't be blank"
    
    # But should NOT show inline error message below the field
    loaded_at_field = find_field("Loaded at")
    # Field should have error class for styling
    assert loaded_at_field[:class].include?("error")
    # But no inline error message should be present after the field
    refute_text "Loaded at can't be blank", count: 2 # Only in alert, not inline
  end

  private

  def switch_account(account)
    visit account_path(account, switch: true)
  end
end