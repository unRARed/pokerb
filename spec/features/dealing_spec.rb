require "spec_helper"

RSpec.describe "Dealing", type: :feature do
  it "is relative to the button" do
    User.create(
      name: "Foo", password: "password", email: "Foo@rbpkr.com"
    )
    User.create(
      name: "Bar", password: "password", email: "Bar@rbpkr.com"
    )
    User.create(
      name: "Baz", password: "password", email: "Baz@rbpkr.com"
    )
    visit "/login"
    fill_in "user[email]", with: "Foo@rbpkr.com"
    fill_in "user[password]", with: "password"
    click_on "Sign in"

    click_on "Let's go"
    click_on "Start the Game"
    community_url = current_url
    visit community_url.split("/community").first
    click_on "Join now"

    ["Bar", "Baz"].each do |name|
      using_session(name) do
        join_game(community_url, name)
      end
    end

    visit community_url
    expect(page).to have_selector(".player-info__name", count: 3)

    # No one is the dealer yet... make it so
    click_on "Draw for the Button"

    dealers = []
    dealer_selector = ".player-info__name.player-info__dealer"

    page.find(dealer_selector)

    within ".player-info" do
      expect(dealers).not_to include(find(dealer_selector).text)
      dealers << find(dealer_selector).text
    end

    advance_game

    # It's next player's turn to deal
    within ".player-info" do
      expect(dealers).not_to include(find(dealer_selector).text)
      dealers << find(dealer_selector).text
    end

    advance_game

    # It's third player's turn to deal
    within ".player-info" do
      expect(dealers).not_to include(find(dealer_selector).text)
      dealers << find(dealer_selector).text
    end

    advance_game

    # It's back to the first player
    within ".player-info" do
      expect(dealers.first).to eq(find(dealer_selector).text)
    end
  end

  def join_game(url, player_name)
    visit "/login"
    fill_in "user[email]", with: "#{player_name}@rbpkr.com"
    fill_in "user[password]", with: "password"
    click_on "Sign in"

    visit url.split("/community").first
    click_on "Join"
  end

  def advance_game
    5.times{ find(id: "advance").find("a").click }
  end
end
