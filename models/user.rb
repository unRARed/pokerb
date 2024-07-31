class User < ActiveRecord::Base
  has_secure_password

  validates :name,
    presence: true,
    format: {
      with: /\A[a-zA-Z]{3,16}\z/,
      message: 'must be 3-16 letters'
    },
    if: -> { !new_record? }
  validates :email,
    presence: true,
    uniqueness: true,
    format: { with: /\w+@\w+\.\w+/ }
  validates :password,
    presence: true,
    length: { minimum: 8 },
    if: -> { new_record? || !password.nil? }
end
