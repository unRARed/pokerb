require "spec_helper"

RSpec.describe "Dealing", type: :feature do
  it "is relative to the button" do
    User.create(
      name: "Foo", password: "password", email: "foo@rbpkr.com"
    )
    User.create(
      name: "Bar", password: "password", email: "bar@rbpkr.com"
    )
    User.create(
      name: "Baz", password: "password", email: "baz@rbpkr.com"
    )
    visit "/login"
    fill_in "user[email]", with: "foo@rbpkr.com"
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
    expect(page).to have_selector(".player", count: 3)

    # No one is the dealer yet... make it so
    click_on "Draw for Button"

    dealers = []

    within ".player--dealer" do
      expect(dealers).not_to include(find(".player__name").text)
      dealers << find(".player__name").text
    end

    advance_game

    # It's next player's turn to deal
    within ".player--dealer" do
      expect(dealers).not_to include(find(".player__name").text)
      dealers << find(".player__name").text
    end

    advance_game

    # It's third player's turn to deal
    within ".player--dealer" do
      expect(dealers).not_to include(find(".player__name").text)
      dealers << find(".player__name").text
    end

    advance_game

    # It's back to the first player
    within ".player--dealer" do
      expect(dealers.first).to eq(find(".player__name").text)
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
    click_on "Deal Cards"
    click_on "Head to the Flop"
    3.times{ find(id: "advance").find("a").click }
  end
end
