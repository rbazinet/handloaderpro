require "test_helper"

class CartridgeTest < ActiveSupport::TestCase
  test "should have required associations" do
    cartridge = cartridges(:lapua_308)

    assert_not_nil cartridge.cartridge_type
  end

  test "should belong to cartridge_type" do
    cartridge = cartridges(:lapua_308)

    assert_equal cartridge_types(:rifle), cartridge.cartridge_type
  end

  test "should have many bullet_weights" do
    cartridge = cartridges(:lapua_308)

    assert_respond_to cartridge, :bullet_weights
  end

  test "should have required associations defined" do
    # Test belongs_to association
    reflection = Cartridge.reflect_on_association(:cartridge_type)
    assert_not_nil reflection, "cartridge_type association should be defined"
    assert_equal :belongs_to, reflection.macro, "cartridge_type should be belongs_to"

    # Test has_many association
    reflection = Cartridge.reflect_on_association(:bullet_weights)
    assert_not_nil reflection, "bullet_weights association should be defined"
    assert_equal :has_many, reflection.macro, "bullet_weights should be has_many"
  end

  test "should require name" do
    cartridge = Cartridge.new(cartridge_type: cartridge_types(:rifle))
    assert_not cartridge.valid?
    assert_includes cartridge.errors[:name], "can't be blank"
  end

  test "should require unique name scoped to cartridge_type" do
    existing_cartridge = cartridges(:lapua_308)
    cartridge = Cartridge.new(
      name: existing_cartridge.name,
      cartridge_type: existing_cartridge.cartridge_type
    )

    assert_not cartridge.valid?
    assert_includes cartridge.errors[:name], "has already been taken"
  end

  test "should allow same name for different cartridge_types" do
    cartridge = Cartridge.new(
      name: cartridges(:lapua_308).name,
      cartridge_type: cartridge_types(:pistol)  # Different cartridge type
    )

    assert cartridge.valid?
  end

  test "should have name" do
    cartridge = cartridges(:lapua_308)

    assert_not_nil cartridge.name
    assert_kind_of String, cartridge.name
  end

  test "should have for_cartridge_type scope" do
    rifle_cartridges = Cartridge.for_cartridge_type(cartridge_types(:rifle).id)

    rifle_cartridges.each do |cartridge|
      assert_equal cartridge_types(:rifle).id, cartridge.cartridge_type_id
    end
  end

  test "should have for_select class method" do
    assert_respond_to Cartridge, :for_select

    options = Cartridge.for_select(cartridge_types(:rifle).id)
    assert_kind_of Array, options

    options.each do |option|
      assert_kind_of Array, option
      assert_equal 2, option.length
      assert_kind_of String, option[0]  # name
      assert_kind_of Integer, option[1] # id
    end
  end

  test "should be valid with valid attributes" do
    cartridge = Cartridge.new(
      name: "Test Cartridge",
      cartridge_type: cartridge_types(:rifle)
    )

    assert cartridge.valid?
  end
end
