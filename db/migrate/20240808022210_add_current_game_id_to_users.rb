class AddCurrentGameIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :current_game_id, :integer
  end
end
