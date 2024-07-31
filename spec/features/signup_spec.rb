require "spec_helper"
require 'securerandom'

RSpec.describe "User signs up", type: :feature do
  it "successfully" do
    visit "/signup"

    fill_in "user[email]", with: "#{SecureRandom.hex}@email.com"
    fill_in "user[password]", with: "password"
    expect{click_on "Sign up"}.to change{User.count}.by(1)

    fill_in "user[name]", with: "durrrr"
    click_on "Set my name"

    expect(page).to have_content("Welcome, durrrr")
  end
end
