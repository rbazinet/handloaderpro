require "test_helper"

class PrimerTest < ActiveSupport::TestCase
  test "should have required associations" do
    primer = primers(:cci_br2)

    assert_not_nil primer.manufacturer
  end

  test "should belong to manufacturer" do
    primer = primers(:cci_br2)

    assert_equal manufacturers(:cci), primer.manufacturer
  end

  test "should have required associations defined" do
    reflection = Primer.reflect_on_association(:manufacturer)
    assert_not_nil reflection, "manufacturer association should be defined"
    assert_equal :belongs_to, reflection.macro, "manufacturer should be belongs_to"
  end

  test "should require name" do
    primer = Primer.new(manufacturer: manufacturers(:cci))
    assert_not primer.valid?
    assert_includes primer.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    existing_primer = primers(:cci_br2)
    primer = Primer.new(name: existing_primer.name, manufacturer: manufacturers(:cci))

    assert_not primer.valid?
    assert_includes primer.errors[:name], "has already been taken"
  end

  test "should have name" do
    primer = primers(:cci_br2)

    assert_not_nil primer.name
    assert_kind_of String, primer.name
  end

  test "should be valid with valid attributes" do
    primer = Primer.new(
      name: "Test Primer",
      manufacturer: manufacturers(:cci)
    )

    assert primer.valid?
  end
end
