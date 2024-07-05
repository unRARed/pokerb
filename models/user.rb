class User < ActiveRecord::Base
  has_secure_password

  validates :name,
    presence: true
  validates :email,
    presence: true,
    uniqueness: true,
    format: { with: /\w+@\w+\.\w+/ }
  validates :password,
    presence: true,
    length: { minimum: 8 },
    if: -> { new_record? || !password.nil? }
end
