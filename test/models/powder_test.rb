require "test_helper"

class PowderTest < ActiveSupport::TestCase
  test "should have required associations" do
    powder = powders(:varget)

    assert_not_nil powder.manufacturer
  end

  test "should belong to manufacturer" do
    powder = powders(:varget)

    assert_equal manufacturers(:hodgdon), powder.manufacturer
  end

  test "should have required associations defined" do
    reflection = Powder.reflect_on_association(:manufacturer)
    assert_not_nil reflection, "manufacturer association should be defined"
    assert_equal :belongs_to, reflection.macro, "manufacturer should be belongs_to"
  end

  test "should require name" do
    powder = Powder.new(manufacturer: manufacturers(:hodgdon))
    assert_not powder.valid?
    assert_includes powder.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    existing_powder = powders(:varget)
    powder = Powder.new(name: existing_powder.name, manufacturer: manufacturers(:hodgdon))

    assert_not powder.valid?
    assert_includes powder.errors[:name], "has already been taken"
  end

  test "should have name" do
    powder = powders(:varget)

    assert_not_nil powder.name
    assert_kind_of String, powder.name
  end

  test "should be valid with valid attributes" do
    powder = Powder.new(
      name: "Test Powder",
      manufacturer: manufacturers(:hodgdon)
    )

    assert powder.valid?
  end
end
