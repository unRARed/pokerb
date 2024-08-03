RbPkr
======

[![Ruby](https://github.com/unRARed/rbpkr/actions/workflows/ruby.yml/badge.svg)](https://github.com/unRARed/rbpkr/actions/workflows/ruby.yml)

<img src="https://raw.githubusercontent.com/unRARed/rbpkr/main/rbpkr-slogan.png">

![Community Cards](https://raw.githubusercontent.com/unRARed/rbpkr/main/community-cards.jpg)

Play Texas Holdem' Poker with your friends... even if they can't
deal for shit. This is NOT meant for production usage. Any use
of this software is of your own risk. This exists to speed up your
home game card dealing. If you have a cool idea, submit an issue,
or better yet, a PR.

<img align="left" src="https://raw.githubusercontent.com/unRARed/rbpkr/main/hand_1.jpg">

**What does it do?**

- Deals cards for a Texas Hold'em home game
- Keeps track of the players with a session
- Rotates the dealer button, player to player
- Offers a choice of card-backs (thanks Billy T.)
- Also, it allows the game manager/creator to:
  - Advance the game/deck state
  - Remove players from the game (stale sessions)

**WHAT IT DOES NOT DO (at least yet)**

- It does not... Deal other game formats
- It does not... Track hand history
- It does not... Determine winners
- It does not... Handle betting / pots

**Why?**

- Dealing wastes a lot of time
  (see online vs. live poker hands per hour stats)
- People suck at dealing. I took a course even, and I still suck.
- Low stakes cash games can't support paying for a dealer.
- `rand()` > Dealer

### It also has a Dark Mode

![Dark Mode](https://raw.githubusercontent.com/unRARed/rbpkr/main/dark-mode.jpg)

Running the Server
------------------

- First `bundle install`
- Then run `bin/dev' to start the server
  - The server runs from `http://127.0.0.1:9292` by default
- To expose to your network, set `RACK_ENV=production`
  - Further, add `RBPKR_HOSTNAME=yourdomain.com rackup` to specify
    host for qrcode
  - Use `DEBUG=1 rackup` to view debug logging

**Client Access**

- Browse to `http://RBPKR_HOSTNAME:9292` on tablet / shared device
- Set a user name and create a new game
- Scan QR code from other device(s) to join the game

**Development**

- `rspec spec` runs the test suite
- `ruby db/seed.rb` creates a game with 1 owner and 9 players
  the emails are userNUM@example.com
  the passwords are 'password'
- Environment variables:
  - `RBPKR_HOSTNAME` - the hostname to use for QR code
  - `DEBUG` - set to 1 to enable debug logging
  - `RACK_ENV` - set to production to expose to network
  - `RBPKR_RECAPTCHA_SITE_KEY` - set to your recaptcha site key
  - `RBPKR_RECAPTCHA_SECRET_KEY` - set to your recaptcha secret key

**Conventions**

- the `@state` instance variable should only contain YAML-seriazable
  data and be translated to more meaningful data as part of the
  initialization process.

<img align="left" src="https://raw.githubusercontent.com/unRARed/rbpkr/main/hand_back.jpg">

