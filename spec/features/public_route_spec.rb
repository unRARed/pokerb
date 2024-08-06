require "spec_helper"

RSpec.describe "Public routes", type: :feature do
  user = User.create!(
    name: "SomeUser",
    password: "password",
    email: "some@email.com",
    email_confirmed_at: Time.now,
  )
  Game.create!(
    slug: "TEST",
    password: "",
    button_index: nil,
    user_id: user.id,
  )
  it "doesn't require a session" do
    [
      "/", "/login",
      "/signup", "/confirm",
      "/set_name", "/cleanup", "/set_name",
      "/images/rbpkr.png"
    ].each{ |path| visit path; access_granted; }
  end

  def access_granted
    expect(page).
      not_to have_content("You must be signed in to do that")
  end
end
