require "test_helper"

class BulletTest < ActiveSupport::TestCase
  test "should have required associations" do
    bullet = bullets(:sierra_168)

    assert_not_nil bullet.manufacturer
    assert_not_nil bullet.caliber
  end

  test "should belong to manufacturer" do
    bullet = bullets(:sierra_168)

    assert_equal manufacturers(:sierra), bullet.manufacturer
  end

  test "should belong to caliber" do
    bullet = bullets(:sierra_168)

    assert_equal calibers(:cal_308), bullet.caliber
  end

  test "should have required associations defined" do
    associations = [:manufacturer, :caliber]

    associations.each do |association|
      reflection = Bullet.reflect_on_association(association)
      assert_not_nil reflection, "#{association} association should be defined"
      assert_equal :belongs_to, reflection.macro, "#{association} should be belongs_to"
    end
  end

  test "should have name" do
    bullet = bullets(:sierra_168)

    assert_not_nil bullet.name
    assert_kind_of String, bullet.name
  end

  test "should have numeric attributes" do
    bullet = bullets(:sierra_168)

    if bullet.bc.present?
      assert_kind_of BigDecimal, bullet.bc
    end

    if bullet.weight.present?
      assert_kind_of BigDecimal, bullet.weight
    end

    if bullet.length.present?
      assert_kind_of BigDecimal, bullet.length
    end

    if bullet.sd.present?
      assert_kind_of BigDecimal, bullet.sd
    end
  end
end
