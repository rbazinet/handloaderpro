require "test_helper"

class BulletWeightTest < ActiveSupport::TestCase
  test "should have required associations" do
    bullet_weight = bullet_weights(:weight_168)

    assert_not_nil bullet_weight.cartridge_types
    assert bullet_weight.cartridge_types.any?
  end

  test "should have many cartridge types" do
    bullet_weight = bullet_weights(:weight_168)

    assert bullet_weight.cartridge_types.include?(cartridge_types(:rifle))
  end

  test "should have required associations defined" do
    reflection = BulletWeight.reflect_on_association(:cartridge_types)
    assert_not_nil reflection, "cartridge_types association should be defined"
    assert_equal :has_many, reflection.macro, "cartridge_types should be has_many"
  end

  test "should require weight" do
    bullet_weight = BulletWeight.new
    assert_not bullet_weight.valid?
    assert_includes bullet_weight.errors[:weight], "can't be blank"
  end

  test "should require unique weight" do
    existing_weight = bullet_weights(:weight_168)
    bullet_weight = BulletWeight.new(
      weight: existing_weight.weight
    )

    assert_not bullet_weight.valid?
    assert_includes bullet_weight.errors[:weight], "has already been taken"
  end

  test "should not allow duplicate weights" do
    bullet_weight = BulletWeight.new(
      weight: bullet_weights(:weight_168).weight
    )

    assert_not bullet_weight.valid?
    assert_includes bullet_weight.errors[:weight], "has already been taken"
  end

  test "should have weight" do
    bullet_weight = bullet_weights(:weight_168)

    assert_not_nil bullet_weight.weight
    assert_kind_of Numeric, bullet_weight.weight
  end

  test "should have for_select class method" do
    cartridge_type = cartridge_types(:rifle)
    options = BulletWeight.for_select(cartridge_type.id)

    assert_kind_of Array, options
    options.each do |option|
      assert_kind_of Array, option
      assert_equal 2, option.length
      assert_kind_of Numeric, option[0]  # weight
      assert_kind_of Integer, option[1]  # id
    end
  end

  test "should respond to for_select" do
    assert_respond_to BulletWeight, :for_select
  end

  test "should be valid with valid attributes" do
    bullet_weight = BulletWeight.new(
      weight: 150.0
    )

    assert bullet_weight.valid?
  end
end
