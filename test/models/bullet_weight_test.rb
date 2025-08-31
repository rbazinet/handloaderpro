require "test_helper"

class BulletWeightTest < ActiveSupport::TestCase
  test "should have required associations" do
    bullet_weight = bullet_weights(:weight_168)

    assert_not_nil bullet_weight.cartridge
  end

  test "should belong to cartridge" do
    bullet_weight = bullet_weights(:weight_168)

    assert_equal cartridges(:lapua_308), bullet_weight.cartridge
  end

  test "should have required associations defined" do
    reflection = BulletWeight.reflect_on_association(:cartridge)
    assert_not_nil reflection, "cartridge association should be defined"
    assert_equal :belongs_to, reflection.macro, "cartridge should be belongs_to"
  end

  test "should require weight" do
    bullet_weight = BulletWeight.new(cartridge: cartridges(:lapua_308))
    assert_not bullet_weight.valid?
    assert_includes bullet_weight.errors[:weight], "can't be blank"
  end

  test "should require unique weight scoped to cartridge" do
    existing_weight = bullet_weights(:weight_168)
    bullet_weight = BulletWeight.new(
      weight: existing_weight.weight,
      cartridge: existing_weight.cartridge
    )

    assert_not bullet_weight.valid?
    assert_includes bullet_weight.errors[:weight], "has already been taken"
  end

  test "should allow same weight for different cartridges" do
    bullet_weight = BulletWeight.new(
      weight: bullet_weights(:weight_168).weight,
      cartridge: cartridges(:federal_308)  # Different cartridge
    )

    assert bullet_weight.valid?
  end

  test "should have weight" do
    bullet_weight = bullet_weights(:weight_168)

    assert_not_nil bullet_weight.weight
    assert_kind_of Numeric, bullet_weight.weight
  end

  test "should have for_cartridge scope" do
    cartridge_weights = BulletWeight.for_cartridge(cartridges(:lapua_308).id)

    cartridge_weights.each do |weight|
      assert_equal cartridges(:lapua_308).id, weight.cartridge_id
    end
  end

  test "should have for_select class method" do
    assert_respond_to BulletWeight, :for_select

    options = BulletWeight.for_select(cartridges(:lapua_308).id)
    assert_kind_of Array, options

    options.each do |option|
      assert_kind_of Array, option
      assert_equal 2, option.length
      assert_kind_of Numeric, option[0]  # weight
      assert_kind_of Integer, option[1]     # id
    end
  end

  test "should be valid with valid attributes" do
    bullet_weight = BulletWeight.new(
      weight: 150.0,
      cartridge: cartridges(:lapua_308)
    )

    assert bullet_weight.valid?
  end
end
