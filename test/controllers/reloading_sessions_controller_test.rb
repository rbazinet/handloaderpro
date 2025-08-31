require "test_helper"

class ReloadingSessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @account = accounts(:one)
    @user = users(:one)
    @user.account_users.find_or_create_by!(account: @account) { |au| au.admin = true }
    sign_in @user
    Current.account = @account

    @reloading_session = reloading_sessions(:session_one)
  end

  test "should get index" do
    get reloading_sessions_url
    assert_response :success
    assert_select "h1", "Reloading Sessions"
  end

  test "should get new" do
    get new_reloading_session_url
    assert_response :success
    assert_select "h1", "New Reloading Session"
  end

  test "should create reloading_session" do
    assert_difference("ReloadingSession.count") do
      post reloading_sessions_url, params: {
        reloading_session: {
          cartridge_id: cartridges(:lapua_308).id,
          cartridge_type_id: cartridge_types(:brass).id,
          loaded_at: Date.current,
          reloading_data_source_id: reloading_data_sources(:hodgdon).id,
          bullet_id: bullets(:sierra_168).id,
          bullet_type: "BTHP",
          bullet_weight_id: bullet_weights(:weight_168).id,
          powder_id: powders(:varget).id,
          powder_weight: 42.5,
          primer_id: primers(:cci_br2).id,
          primer_type_id: primer_types(:large_rifle).id,
          cartridge_overall_length: 2.800,
          quantity: 20,
          notes: "Test creation"
        }
      }
    end

    assert_redirected_to reloading_session_url(ReloadingSession.last)
  end

  test "should create reloading_session with custom data source" do
    assert_difference("ReloadingSession.count") do
      post reloading_sessions_url, params: {
        reloading_session: {
          cartridge_id: cartridges(:lapua_308).id,
          cartridge_type_id: cartridge_types(:brass).id,
          loaded_at: Date.current,
          reloading_data_source_id: reloading_data_sources(:other).id,
          custom_data_source_name: "My Custom Source",
          bullet_id: bullets(:sierra_168).id,
          bullet_weight_id: bullet_weights(:weight_168).id,
          powder_id: powders(:varget).id,
          powder_weight: 42.5,
          primer_id: primers(:cci_br2).id,
          primer_type_id: primer_types(:large_rifle).id,
          quantity: 20
        }
      }
    end

    session = ReloadingSession.last
    assert_equal "My Custom Source", session.custom_data_source_name
    assert_redirected_to reloading_session_url(session)
  end

  test "should show reloading_session" do
    get reloading_session_url(@reloading_session)
    assert_response :success
    assert_select "h1", "Reloading Session Details"
  end

  test "should get edit" do
    get edit_reloading_session_url(@reloading_session)
    assert_response :success
    assert_select "h1", "Edit Reloading Session"
  end

  test "should update reloading_session" do
    patch reloading_session_url(@reloading_session), params: {
      reloading_session: {
        quantity: 25,
        notes: "Updated notes"
      }
    }

    assert_redirected_to reloading_session_url(@reloading_session)
    @reloading_session.reload
    assert_equal 25, @reloading_session.quantity
    assert_equal "Updated notes", @reloading_session.notes
  end

  test "should destroy reloading_session" do
    assert_difference("ReloadingSession.count", -1) do
      delete reloading_session_url(@reloading_session)
    end

    assert_redirected_to reloading_sessions_url
  end

  test "should require authentication" do
    sign_out @user

    get reloading_sessions_url
    assert_redirected_to new_user_session_url
  end

  test "should scope to current account" do
    other_account = Account.create!(name: "Other Account", owner: @user)
    ReloadingSession.create!(
      account: other_account,
      cartridge: cartridges(:lapua_308),
      cartridge_type: cartridge_types(:brass),
      reloading_data_source: reloading_data_sources(:hodgdon),
      bullet: bullets(:sierra_168),
      bullet_weight: bullet_weights(:weight_168),
      powder: powders(:varget),
      powder_weight: 42.5,
      primer: primers(:cci_br2),
      primer_type: primer_types(:large_rifle),
      quantity: 10
    )

    get reloading_sessions_url
    assert_response :success

    # Should only see sessions from current account
    assert_select "tbody tr", count: @account.reloading_sessions.count
  end
end
