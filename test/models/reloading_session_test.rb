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

  # Validation Tests
  test "should require loaded_at" do
    session = build_valid_session
    session.loaded_at = nil

    assert_not session.valid?
    assert_includes session.errors[:loaded_at], "can't be blank"
  end

  test "should validate quantity is integer when present" do
    session = build_valid_session
    session.quantity = 10.5

    assert_not session.valid?
    assert_includes session.errors[:quantity], "must be an integer"
  end

  test "should validate quantity is positive when present" do
    session = build_valid_session
    session.quantity = -5

    assert_not session.valid?
    assert_includes session.errors[:quantity], "must be greater than 0"
  end

  test "should allow nil quantity" do
    session = build_valid_session
    session.quantity = nil

    assert session.valid?
  end

  test "should validate cartridge_overall_length is positive when present" do
    session = build_valid_session
    session.cartridge_overall_length = -1.0

    assert_not session.valid?
    assert_includes session.errors[:cartridge_overall_length], "must be greater than 0"
  end

  test "should validate powder_weight is positive when present" do
    session = build_valid_session
    session.powder_weight = -5.0

    assert_not session.valid?
    assert_includes session.errors[:powder_weight], "must be greater than 0"
  end

  test "should validate bullet_weight_other is positive when present" do
    session = build_valid_session
    session.bullet_weight_other = -10.5

    assert_not session.valid?
    assert_includes session.errors[:bullet_weight_other], "must be greater than 0"
  end

  # Bullet Weight Validation Tests
  test "should be valid with bullet_weight_id and no custom weight" do
    session = build_valid_session
    session.bullet_weight = bullet_weights(:weight_168)
    session.bullet_weight_other = nil

    assert session.valid?
  end

  test "should be valid with custom weight and no bullet_weight_id" do
    session = build_valid_session
    session.bullet_weight = nil
    session.bullet_weight_other = 168.25

    assert session.valid?
  end

  test "should be valid with both bullet_weight_id and custom weight" do
    session = build_valid_session
    session.bullet_weight = bullet_weights(:weight_168)
    session.bullet_weight_other = 168.25

    assert session.valid?
  end

  test "should require either bullet_weight_id or custom weight" do
    session = build_valid_session
    session.bullet_weight = nil
    session.bullet_weight_other = nil

    assert_not session.valid?
    assert_includes session.errors[:base], "Bullet weight must be selected or custom weight must be entered"
  end

  # Required Association Tests
  test "should require cartridge" do
    session = build_valid_session
    session.cartridge = nil

    assert_not session.valid?
    assert_includes session.errors[:cartridge], "must be selected"
  end

  test "should require cartridge_type" do
    session = build_valid_session
    session.cartridge_type = nil

    assert_not session.valid?
    assert_includes session.errors[:cartridge_type], "must be selected"
  end

  test "should require reloading_data_source" do
    session = build_valid_session
    session.reloading_data_source = nil

    assert_not session.valid?
    assert_includes session.errors[:reloading_data_source], "must be selected"
  end

  test "should require bullet" do
    session = build_valid_session
    session.bullet = nil

    assert_not session.valid?
    assert_includes session.errors[:bullet], "must be selected"
  end

  test "should require powder" do
    session = build_valid_session
    session.powder = nil

    assert_not session.valid?
    assert_includes session.errors[:powder], "must be selected"
  end

  test "should require primer" do
    session = build_valid_session
    session.primer = nil

    assert_not session.valid?
    assert_includes session.errors[:primer], "must be selected"
  end

  test "should require primer_type" do
    session = build_valid_session
    session.primer_type = nil

    assert_not session.valid?
    assert_includes session.errors[:primer_type], "must be selected"
  end

  private

  def build_valid_session
    ReloadingSession.new(
      account: accounts(:one),
      loaded_at: Date.current,
      cartridge: cartridges(:lapua_308),
      cartridge_type: cartridge_types(:rifle),
      reloading_data_source: reloading_data_sources(:hodgdon),
      bullet: bullets(:sierra_168),
      bullet_weight: bullet_weights(:weight_168),
      powder: powders(:varget),
      primer: primers(:cci_br2),
      primer_type: primer_types(:large_rifle),
      quantity: 50,
      cartridge_overall_length: 2.810,
      powder_weight: 42.5,
      bullet_type: "Match",
      notes: "Test load"
    )
  end
end
