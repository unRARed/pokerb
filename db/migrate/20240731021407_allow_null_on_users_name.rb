class AllowNullOnUsersName < ActiveRecord::Migration[7.1]
  def change
    User.all.each do |user|
      next unless user.name.present?

      user.update!(name: user.name.gsub(/[^a-zA-Z]/, ''))
    end
    change_column_null :users, :name, true
  end
end
