require "test_helper"

class CaliberTest < ActiveSupport::TestCase
  test "should have name" do
    caliber = calibers(:cal_308)

    assert_not_nil caliber.name
    assert_kind_of String, caliber.name
  end

  test "should have value" do
    caliber = calibers(:cal_308)

    if caliber.value.present?
      assert_kind_of BigDecimal, caliber.value
    end
  end

  test "should be valid with name only" do
    caliber = Caliber.new(name: "Test Caliber")

    assert caliber.valid?
  end

  test "should be valid with name and value" do
    caliber = Caliber.new(
      name: ".308 Winchester",
      value: 0.308
    )

    assert caliber.valid?
  end

  test "should allow nil value" do
    caliber = Caliber.new(
      name: "Test Caliber",
      value: nil
    )

    assert caliber.valid?
  end
end
