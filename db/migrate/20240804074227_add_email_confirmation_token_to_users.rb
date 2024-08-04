class AddEmailConfirmationTokenToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :email_confirmation_token, :string
    add_column :users, :email_confirmed_at, :datetime

    add_index :users, :email_confirmation_token, unique: true
  end
end
