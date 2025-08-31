require "test_helper"

class ReloadingSessionTest < ActiveSupport::TestCase
  test "should have required associations" do
    session = reloading_sessions(:session_one)

    assert_not_nil session.account
    assert_not_nil session.cartridge
    assert_not_nil session.cartridge_type
    assert_not_nil session.reloading_data_source
    assert_not_nil session.bullet
    assert_not_nil session.bullet_weight
    assert_not_nil session.powder
    assert_not_nil session.primer
    assert_not_nil session.primer_type
  end

  test "should save custom data source name when provided" do
    session = reloading_sessions(:session_two)

    assert_equal "Custom Manual", session.custom_data_source_name
    assert_equal "Other", session.reloading_data_source.name
  end

  test "should belong to account" do
    session = reloading_sessions(:session_one)

    assert_equal accounts(:one), session.account
  end

  test "should have quantity and powder weight as numbers" do
    session = reloading_sessions(:session_one)

    assert_kind_of Integer, session.quantity
    assert_kind_of BigDecimal, session.powder_weight
  end

  test "should allow notes" do
    session = reloading_sessions(:session_one)

    assert_equal "Test load for accuracy", session.notes
  end

  test "should have required associations defined" do
    associations = [:account, :cartridge, :cartridge_type, :reloading_data_source,
      :bullet, :bullet_weight, :powder, :primer, :primer_type]

    associations.each do |association|
      reflection = ReloadingSession.reflect_on_association(association)
      assert_not_nil reflection, "#{association} association should be defined"
      assert_equal :belongs_to, reflection.macro, "#{association} should be belongs_to"
    end
  end
end
