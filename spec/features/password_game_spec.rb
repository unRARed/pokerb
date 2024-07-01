require "spec_helper"

RSpec.describe "Password protection", type: :feature do
  it "prevents unauthorized access" do
    User.create(
      name: "Me", password: "password", email: "Me@rbpkr.com"
    )
    User.create(
      name: "Friend", password: "password", email: "Friend@rbpkr.com"
    )
    visit "/login"
    fill_in "user[email]", with: "Me@rbpkr.com"
    fill_in "user[password]", with: "password"
    click_on "Sign in"

    click_on "Let's go"
    fill_in "password", with: "mypassword"
    click_on "Start the Game"
    community_url = current_url
    visit community_url.split("/community").first

    using_session("friend") do
      visit "/login"
      fill_in "user[email]", with: "Friend@rbpkr.com"
      fill_in "user[password]", with: "password"
      click_on "Sign in"

      visit community_url.split("/community").first
      expect(page).
        to have_content("You must enter the correct password")
      expect(page).to have_content("Enter Password")

      fill_in "password", with: "wrong password"
      click_on "Let me in"
      # why is the Flash not working here?
      #expect(page).to have_content("Password incorrect")
      expect(page).to have_content("Enter Password")

      fill_in "password", with: "mypassword"
      click_on "Let me in"
      # why is the Flash not working here?
      expect(page).to have_content("Password accepted")
      click_on "Join"
      expect(page).to have_content("Waiting for Cards")
    end
  end
end
