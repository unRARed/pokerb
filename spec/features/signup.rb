require "spec_helper"

RSpec.describe "User signs up", type: :feature do
  it "successfully" do
    visit "/signup"

    fill_in "user[name]", with: "Me"
    fill_in "user[password]", with: "password"
    fill_in "user[email]", with: "some@email.com"
    click_on "Sign up"

    expect(page).to have_content("Welcome, Me")
    expect(User.count).to eq(1)
  end
end
