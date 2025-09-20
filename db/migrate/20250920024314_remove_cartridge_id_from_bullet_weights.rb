class RemoveCartridgeIdFromBulletWeights < ActiveRecord::Migration[8.1]
  def change
    remove_reference :bullet_weights, :cartridge, null: false, foreign_key: true
  end
end
