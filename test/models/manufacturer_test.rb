require "test_helper"

class ManufacturerTest < ActiveSupport::TestCase
  test "should have required associations" do
    manufacturer = manufacturers(:sierra)

    assert_not_nil manufacturer.manufacturer_type
  end

  test "should belong to manufacturer_type" do
    manufacturer = manufacturers(:sierra)

    assert_equal manufacturer_types(:bullet), manufacturer.manufacturer_type
  end

  test "should have required associations defined" do
    reflection = Manufacturer.reflect_on_association(:manufacturer_type)
    assert_not_nil reflection, "manufacturer_type association should be defined"
    assert_equal :belongs_to, reflection.macro, "manufacturer_type should be belongs_to"
  end

  test "should require name" do
    manufacturer = Manufacturer.new(manufacturer_type: manufacturer_types(:bullet))
    assert_not manufacturer.valid?
    assert_includes manufacturer.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    existing_manufacturer = manufacturers(:sierra)
    manufacturer = Manufacturer.new(
      name: existing_manufacturer.name,
      manufacturer_type: manufacturer_types(:bullet)
    )

    assert_not manufacturer.valid?
    assert_includes manufacturer.errors[:name], "has already been taken"
  end

  test "should have name" do
    manufacturer = manufacturers(:sierra)

    assert_not_nil manufacturer.name
    assert_kind_of String, manufacturer.name
  end

  test "should be valid with valid attributes" do
    manufacturer = Manufacturer.new(
      name: "Test Manufacturer",
      manufacturer_type: manufacturer_types(:bullet)
    )

    assert manufacturer.valid?
  end
end
