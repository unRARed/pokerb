require './rbpkr'

game = Game.new(
  slug: "TEST",
  password: "",
  button_index: nil,
  step_color: "#a2e7a1",
  deck_phase: "deal",
  card_back: "MudbottomBack.png",
  deck_stack: [
    ["2", "clubs"],
    ["2", "diamonds"],
    ["2", "hearts"],
    ["2", "spades"],
    ["3", "clubs"],
    ["3", "diamonds"],
    ["3", "hearts"],
    ["3", "spades"],
    ["4", "clubs"],
    ["4", "diamonds"],
    ["4", "hearts"],
    ["4", "spades"],
    ["5", "clubs"],
    ["5", "diamonds"],
    ["5", "hearts"],
    ["5", "spades"],
    ["6", "clubs"],
    ["6", "diamonds"],
    ["6", "hearts"],
    ["6", "spades"],
    ["7", "clubs"],
    ["7", "diamonds"],
    ["7", "hearts"],
    ["7", "spades"],
    ["8", "clubs"],
    ["8", "diamonds"],
    ["8", "hearts"],
    ["8", "spades"],
    ["9", "clubs"],
    ["9", "diamonds"],
    ["9", "hearts"],
    ["9", "spades"],
    ["Ace", "clubs"],
    ["Ace", "diamonds"],
    ["Ace", "hearts"],
    ["Ace", "spades"],
    ["Jack", "clubs"],
    ["Jack", "diamonds"],
    ["Jack", "hearts"],
    ["Jack", "spades"],
    ["King", "clubs"],
    ["King", "diamonds"],
    ["King", "hearts"],
    ["King", "spades"],
    ["Queen", "clubs"],
    ["Queen", "diamonds"],
    ["Queen", "hearts"],
    ["Queen", "spades"],
    ["Ten", "clubs"],
    ["Ten", "diamonds"],
    ["Ten", "hearts"],
    ["Ten", "spades"],
  ],
  deck_discarded: [],
  deck_community: [],
)
players = []
10.times do |i|
  user = User.create!(
    name: "RbPkr User#{i+1}",
    password: "password",
    email: "user#{i+1}@example.com",
    created_at: Time.now,
    updated_at: Time.now,
  )
  if i == 0
    game.user_id = user.id
  else
    players << { user_id: user.id, hole_cards: [] }
  end
end
game.players = players
game.save!
