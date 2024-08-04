require "spec_helper"
require 'securerandom'

RSpec.describe "User signs up", type: :feature do
  it "successfully", js: true do
    visit "/signup"

    fill_in "user[email]", with: "#{SecureRandom.hex}@email.com"
    fill_in "user[password]", with: "password"
    expect{click_on "Sign up"}.to change{User.count}.by(1)

    expect(Mail::TestMailer.deliveries.length).to eq(1)
    expect(page).to have_content("Please confirm your account")

    visit "/new"
    # global hook checks for email confirmation
    expect(page).to have_content(
      "confirm your RbPkr account to get in the game"
    )
    user = User.last

    # User clicks on the email confirmation link they received
    visit "/confirm/#{user.email_confirmation_token}"

    expect(user.reload.is_confirmed?).to be(true)

    expect(page).to have_content("Your account has been confirmed")

    # User is redirected to set a name
    fill_in "user[name]", with: "durrrr"
    click_on "Set my name"

    expect(page).to have_content("Welcome, durrrr")
  end
end
