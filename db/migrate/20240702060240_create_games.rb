class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.integer :user_id, null: false, index: true
      t.string :slug, null: false, index: true
      t.string :password
      t.string :step_color
      t.string :card_back
      t.integer :button_index
      t.string :deck_phase, null: false, default: "deal"
      t.json :deck_stack
      t.json :deck_discarded
      t.json :deck_community
      t.json :players

      t.timestamps
    end
  end
end
