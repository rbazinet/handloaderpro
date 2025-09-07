require "test_helper"

class CartridgeTypeTest < ActiveSupport::TestCase
  test "should have many cartridges" do
    cartridge_type = cartridge_types(:rifle)

    assert_respond_to cartridge_type, :cartridges
  end

  test "should have many reloading_sessions" do
    cartridge_type = cartridge_types(:rifle)

    assert_respond_to cartridge_type, :reloading_sessions
  end

  test "should have required associations defined" do
    # Test has_many cartridges
    reflection = CartridgeType.reflect_on_association(:cartridges)
    assert_not_nil reflection, "cartridges association should be defined"
    assert_equal :has_many, reflection.macro, "cartridges should be has_many"

    # Test has_many reloading_sessions
    reflection = CartridgeType.reflect_on_association(:reloading_sessions)
    assert_not_nil reflection, "reloading_sessions association should be defined"
    assert_equal :has_many, reflection.macro, "reloading_sessions should be has_many"
  end

  test "should require name" do
    cartridge_type = CartridgeType.new
    assert_not cartridge_type.valid?
    assert_includes cartridge_type.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    existing_type = cartridge_types(:rifle)
    cartridge_type = CartridgeType.new(name: existing_type.name)

    assert_not cartridge_type.valid?
    assert_includes cartridge_type.errors[:name], "has already been taken"
  end

  test "should have name" do
    cartridge_type = cartridge_types(:rifle)

    assert_not_nil cartridge_type.name
    assert_kind_of String, cartridge_type.name
  end

  test "should have for_select class method" do
    assert_respond_to CartridgeType, :for_select

    options = CartridgeType.for_select
    assert_kind_of Array, options

    options.each do |option|
      assert_kind_of Array, option
      assert_equal 2, option.length
      assert_kind_of String, option[0]  # name
      assert_kind_of Integer, option[1] # id
    end
  end

  test "should be valid with valid attributes" do
    cartridge_type = CartridgeType.new(name: "Test Type")

    assert cartridge_type.valid?
  end
end
