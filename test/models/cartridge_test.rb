require "test_helper"

class CartridgeTest < ActiveSupport::TestCase
  test "should have required associations" do
    cartridge = cartridges(:lapua_308)

    assert_not_nil cartridge.cartridge_types
    assert cartridge.cartridge_types.any?
  end

  test "should have many cartridge_types" do
    cartridge = cartridges(:lapua_308)

    assert cartridge.cartridge_types.include?(cartridge_types(:rifle))
  end

  test "should have many cartridge_types through join table" do
    cartridge = cartridges(:lapua_308)

    assert_respond_to cartridge, :cartridge_types
    assert_respond_to cartridge, :cartridge_type_cartridges
  end

  test "should have required associations defined" do
    # Test join table association
    reflection = Cartridge.reflect_on_association(:cartridge_type_cartridges)
    assert_not_nil reflection, "cartridge_type_cartridges association should be defined"
    assert_equal :has_many, reflection.macro, "cartridge_type_cartridges should be has_many"

    # Test through association
    reflection = Cartridge.reflect_on_association(:cartridge_types)
    assert_not_nil reflection, "cartridge_types association should be defined"
    assert_equal :has_many, reflection.macro, "cartridge_types should be has_many"
  end

  test "should require name" do
    cartridge = Cartridge.new
    assert_not cartridge.valid?
    assert_includes cartridge.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    existing_cartridge = cartridges(:lapua_308)
    cartridge = Cartridge.new(
      name: existing_cartridge.name
    )

    assert_not cartridge.valid?
    assert_includes cartridge.errors[:name], "has already been taken"
  end

  test "should not allow duplicate names" do
    cartridge = Cartridge.new(
      name: cartridges(:lapua_308).name
    )

    assert_not cartridge.valid?
    assert_includes cartridge.errors[:name], "has already been taken"
  end

  test "should have name" do
    cartridge = cartridges(:lapua_308)

    assert_not_nil cartridge.name
    assert_kind_of String, cartridge.name
  end

  test "should be associated with cartridge_types" do
    cartridge = cartridges(:lapua_308)
    cartridge_type = cartridge_types(:rifle)

    assert cartridge.cartridge_types.include?(cartridge_type)
  end

  test "should respond to for_select" do
    assert_respond_to Cartridge, :for_select
  end

  test "should be valid with valid attributes" do
    cartridge = Cartridge.new(
      name: "Test Cartridge"
    )

    assert cartridge.valid?
  end
end
