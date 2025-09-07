class PowderResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :manufacturer
  attribute :cartridge_types, field: CheckboxCollectionField, form: true, index: true, name: "Cartridge Types"
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Customize the display name of records in the admin area
  def self.display_name(record) = "#{record.manufacturer.name} - #{record.name}"

  # Customize the default sort column and direction
  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
