class PrimerTypeResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :cartridge_type_name, index: true
  attribute :cartridge_type
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Add scopes to easily filter records
  scope :rifle
  scope :pistol
  scope :shotgun

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Customize the display name of records in the admin area.
  def self.display_name(record) = "#{record.name} (#{record.cartridge_type.name})"

  # Customize the default sort column and direction.
  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
