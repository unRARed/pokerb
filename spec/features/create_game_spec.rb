require "spec_helper"

RSpec.describe "Creating a Game", type: :feature do
  it "creates a new game" do
    visit "/"
    click_on "Tell me your name"

    fill_in "user", with: "Me"
    click_on "That's me"

    click_on "Let's go"

    click_on "Start the Game"
    expect(page).to have_content("Scan QR to Join")

    click_on "Deal Cards"
    expect(page).not_to have_selector(".card")

    click_on "Head to the Flop"
    expect(page).to have_selector(".card", count: 4)

    # TODO: different driver needed to test this
    #
    # find(id: "advance").find("a").click
    # expect(page).to have_selector(".card", count: 5)
  end
end

