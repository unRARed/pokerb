require "spec_helper"
require 'securerandom'

RSpec.describe "Visitor joins game", type: :feature do
  it "after signing up", js: true do
    manager = User.create(
      name: "Foo", password: "password", email: "Foo@rbpkr.com",
      email_confirmed_at: Time.now
    )
    game = Game.create!(
      slug: "TEST",
      password: "",
      button_index: nil,
      players: [],
      user_id: manager.id
    )
    visit "/TEST"
    expect(page).not_to have_content("You must be signed in")
    expect(page).to have_content("You are not in this game")


    click_on "Join now"
    expect(page).
      to have_content("You must be signed in to do that")
    expect(page).to have_content("LOGIN TO RBPKR")
    click_on "Sign up"

    fill_in "user[email]", with: "#{SecureRandom.hex}@email.com"
    fill_in "user[password]", with: "password"
    expect{click_on "Sign up"}.to change{User.count}.by(1)
    new_user = User.last

    # User clicks on the email confirmation link they received
    visit "/confirm/#{new_user.email_confirmation_token}"

    # User is redirected to set a name
    fill_in "user[name]", with: "durrrr"
    click_on "Set my name"

    expect(page).to have_content(game.slug)
  end
end
