3.times do |i|
  User.create(
    name: "user#{i}",
    email: "user#{i}@rbpkr.com",
    password: "password"
  )
end
