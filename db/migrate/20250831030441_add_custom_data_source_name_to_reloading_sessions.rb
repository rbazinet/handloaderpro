class AddCustomDataSourceNameToReloadingSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :reloading_sessions, :custom_data_source_name, :string
  end
end
