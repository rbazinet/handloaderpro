require "test_helper"

class PrimerTypeTest < ActiveSupport::TestCase
  test "should require name" do
    primer_type = PrimerType.new
    assert_not primer_type.valid?
    assert_includes primer_type.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    existing_type = primer_types(:large_rifle)
    primer_type = PrimerType.new(name: existing_type.name)

    assert_not primer_type.valid?
    assert_includes primer_type.errors[:name], "has already been taken"
  end

  test "should have name" do
    primer_type = primer_types(:large_rifle)

    assert_not_nil primer_type.name
    assert_kind_of String, primer_type.name
  end

  test "should be valid with valid attributes" do
    primer_type = PrimerType.new(name: "Test Primer Type")

    assert primer_type.valid?
  end
end
