require "test_helper"

class ManufacturerTypeTest < ActiveSupport::TestCase
  test "should require name" do
    manufacturer_type = ManufacturerType.new
    assert_not manufacturer_type.valid?
    assert_includes manufacturer_type.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    existing_type = manufacturer_types(:bullet)
    manufacturer_type = ManufacturerType.new(name: existing_type.name)

    assert_not manufacturer_type.valid?
    assert_includes manufacturer_type.errors[:name], "has already been taken"
  end

  test "should have name" do
    manufacturer_type = manufacturer_types(:bullet)

    assert_not_nil manufacturer_type.name
    assert_kind_of String, manufacturer_type.name
  end

  test "should be valid with valid attributes" do
    manufacturer_type = ManufacturerType.new(name: "Test Type")

    assert manufacturer_type.valid?
  end
end
