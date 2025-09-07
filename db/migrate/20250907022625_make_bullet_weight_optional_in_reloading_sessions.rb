class MakeBulletWeightOptionalInReloadingSessions < ActiveRecord::Migration[8.0]
  def change
    change_column_null :reloading_sessions, :bullet_weight_id, true
  end
end
