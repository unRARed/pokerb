require "spec_helper"
require 'securerandom'

RSpec.describe "Creating a Game", type: :feature do
  it "creates a new game" do
    email = "#{SecureRandom.hex}@email.com"
    User.create!(
      name: "SomeUser",
      password: "password",
      email: email,
      email_confirmed_at: Time.now,
    )
    visit "/new"
    expect(page).
      to have_content("You must be signed in to do that")

    visit "/login"
    fill_in "user[email]", with: email
    fill_in "user[password]", with: "password"
    click_on "Sign in"

    click_on "Let's go"

    click_on "Start the Game"
    expect(page).to have_content("JOIN THE GAME")

    # Dealer adds himself
    community_url = current_url
    visit community_url.split("/community").first
    click_on "Join now"
    visit community_url

    # Now we can deal
    find(id: "advance").find("a").click
    # Or not, because we haven't determined the button yet
    expect(page).to have_content("Draw for the button first")

    click_on "Draw for the Button"
    expect(page).to have_content("Touch the deck to deal players")
    # Ok, now we can really deal
    find(id: "advance").find("a").click

    expect(page).to have_content("touch the deck to deal the Flop")

    # Show the flop
    find(id: "advance").find("a").click
    expect(page).to have_selector(".playing-card--back", count: 1)
    expect(page).to have_selector(".playing-card--face", count: 3)

    # Show the turn
    find(id: "advance").find("a").click
    expect(page).to have_selector(".playing-card--face", count: 4)

    # Show the river
    find(id: "advance").find("a").click
    expect(page).to have_selector(".playing-card--face", count: 5)

    # Return to the pre-deal state
    find(id: "advance").find("a").click
    expect(page).to have_content("Touch the deck to deal players")
  end
end
