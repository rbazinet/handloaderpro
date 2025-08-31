require "application_system_test_case"

class ReloadingSessionsTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    @account = accounts(:one)
    @user = users(:one)
    @user.account_users.find_or_create_by!(account: @account) { |au| au.admin = true }
    login_as @user
    Current.account = @account

    @reloading_session = reloading_sessions(:session_one)
  end

  test "visiting the index" do
    visit reloading_sessions_url

    assert_selector "h1", text: "Reloading Sessions"
    assert_selector "a", text: "New Reloading Session"

    # Should show existing sessions
    assert_text "Sierra MatchKing 168gr BTHP"
    assert_text "Hodgdon Varget"
  end

  test "should create reloading session" do
    visit reloading_sessions_url
    click_on "New Reloading Session"

    assert_selector "h1", text: "New Reloading Session"

    # Fill in basic information
    fill_in "Quantity", with: 25
    fill_in "Cartridge Overall Length (inches)", with: 2.800

    # Select data source
    select "Hodgdon Reloading", from: "Data Source"

    # Select components
    select "Lapua .308 Win", from: "Cartridge"
    select "Brass", from: "Cartridge Type"
    select "Sierra MatchKing 168gr BTHP", from: "Bullet"
    select "168.0 grains", from: "Bullet Weight"
    select "Hodgdon Varget", from: "Powder"
    fill_in "Powder Weight (grains)", with: 42.5
    select "CCI BR2", from: "Primer"
    select "Large Rifle", from: "Primer Type"

    # Add notes
    fill_in "Notes", with: "Test system creation"

    click_on "Create Reloading session"

    assert_text "Reloading session was successfully created."
    assert_selector "h1", text: "Reloading Session Details"
    assert_text "25 rounds"
    assert_text "Test system creation"
  end

  test "should create reloading session with custom data source" do
    visit new_reloading_session_url

    # Fill in required fields
    fill_in "Quantity", with: 30

    # Select "Other" data source
    select "Other", from: "Data Source"

    # Custom data source field should appear
    assert_selector "input[placeholder='Enter custom data source name']", visible: true
    fill_in "Custom Data Source Name", with: "My Custom Manual"

    # Fill in components
    select "Lapua .308 Win", from: "Cartridge"
    select "Brass", from: "Cartridge Type"
    select "Sierra MatchKing 168gr BTHP", from: "Bullet"
    select "168.0 grains", from: "Bullet Weight"
    select "Hodgdon Varget", from: "Powder"
    fill_in "Powder Weight (grains)", with: 43.0
    select "CCI BR2", from: "Primer"
    select "Large Rifle", from: "Primer Type"

    click_on "Create Reloading session"

    assert_text "Reloading session was successfully created."
    assert_text "My Custom Manual" # Should show custom data source name
  end

  test "should update reloading session" do
    visit reloading_session_url(@reloading_session)
    click_on "Edit"

    assert_selector "h1", text: "Edit Reloading Session"

    fill_in "Quantity", with: 35
    fill_in "Notes", with: "Updated notes from system test"

    click_on "Update Reloading session"

    assert_text "Reloading session was successfully updated."
    assert_text "35 rounds"
    assert_text "Updated notes from system test"
  end

  test "should show and hide custom data source field" do
    visit new_reloading_session_url

    # Initially hidden
    assert_selector "input[placeholder='Enter custom data source name']", visible: false

    # Show when "Other" selected
    select "Other", from: "Data Source"
    assert_selector "input[placeholder='Enter custom data source name']", visible: true

    # Hide when different option selected
    select "Hodgdon Reloading", from: "Data Source"
    assert_selector "input[placeholder='Enter custom data source name']", visible: false
  end

  test "should delete reloading session" do
    visit reloading_session_url(@reloading_session)

    click_on "Delete"

    assert_text "Reloading session was successfully deleted."
    assert_current_path reloading_sessions_path
  end

  test "should navigate between pages" do
    visit reloading_sessions_url

    # Click on a session
    click_on "View", match: :first
    assert_selector "h1", text: "Reloading Session Details"

    # Go back to index
    click_on "Back to Sessions"
    assert_selector "h1", text: "Reloading Sessions"
  end
end
