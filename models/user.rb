class User < ActiveRecord::Base
  has_secure_password
  has_secure_token :email_confirmation_token

  validates :name,
    presence: true,
    format: {
      with: /\A[a-zA-Z\d]{3,16}\z/,
      message: 'must be 3-16 letters or numbers'
    },
    if: ->(user) { user.is_confirmed? }
  validates :email,
    presence: true,
    uniqueness: true,
    format: { with: /\w+@\w+\.\w+/ }
  validates :password,
    presence: true,
    length: { minimum: 8 },
    if: -> { new_record? || !password.nil? }

  def is_confirmed?; !email_confirmed_at.nil? end
end
