require "test_helper"

class ReloadingDataSourceTest < ActiveSupport::TestCase
  test "should require name" do
    data_source = ReloadingDataSource.new
    assert_not data_source.valid?
    assert_includes data_source.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    existing_source = reloading_data_sources(:hodgdon)
    data_source = ReloadingDataSource.new(name: existing_source.name)

    assert_not data_source.valid?
    assert_includes data_source.errors[:name], "has already been taken"
  end

  test "should have name" do
    data_source = reloading_data_sources(:hodgdon)

    assert_not_nil data_source.name
    assert_kind_of String, data_source.name
  end

  test "should have for_select class method" do
    assert_respond_to ReloadingDataSource, :for_select

    options = ReloadingDataSource.for_select
    assert_kind_of Array, options

    options.each do |option|
      assert_kind_of Array, option
      assert_equal 2, option.length
      assert_kind_of String, option[0]  # name
      assert_kind_of Integer, option[1] # id
    end
  end

  test "should be valid with valid attributes" do
    data_source = ReloadingDataSource.new(name: "Test Data Source")

    assert data_source.valid?
  end
end
