require "spec_helper"
require "./models/user"

RSpec.describe "User signs up", type: :feature do
  it "successfully" do
    User.create(
      name: "Some User",
      password: "password",
      email: "some@email.com"
    )
    visit "/login"

    fill_in "user[email]", with: "some@email.com"
    fill_in "user[password]", with: "password1"
    click_on "Sign in"

    expect(page).to have_content("Try again")

    fill_in "user[email]", with: "some@email.com"
    fill_in "user[password]", with: "password"
    click_on "Sign in"

    expect(page).to have_content("Welcome back")
  end
end
