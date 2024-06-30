require "spec_helper"

RSpec.describe "Creating a Game", type: :feature do
  it "creates a new game" do
    User.create(
      name: "Some User",
      password: "password",
      email: "some@email.com"
    )
    visit "/login"
    fill_in "user[email]", with: "some@email.com"
    fill_in "user[password]", with: "password"
    click_on "Sign in"

    click_on "Let's go"

    click_on "Start the Game"
    expect(page).to have_content("Scan QR to Join")

    # Dealer adds himself
    community_url = current_url
    visit community_url.split("/community").first
    click_on "Join now"
    visit community_url

    # Now we can deal
    click_on "Deal Cards"
    # Or not, because we haven't determined the button yet
    expect(page).to have_content("Determine the button first")

    click_on "Draw for Button"
    # Ok, now we can really deal
    click_on "Deal Cards"

    # Show the flop
    click_on "Head to the Flop"
    expect(page).to have_selector(".card--back", count: 1)
    expect(page).to have_selector(".card--face", count: 3)

    # Show the turn
    find(id: "advance").find("a").click
    expect(page).to have_selector(".card--face", count: 4)

    # Show the river
    find(id: "advance").find("a").click
    expect(page).to have_selector(".card--face", count: 5)

    # Return to the pre-deal state
    find(id: "advance").find("a").click
    expect(page).to have_content("Scan QR to Join")
  end
end
