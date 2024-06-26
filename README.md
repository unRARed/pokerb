RbPkr
======

[![Ruby](https://github.com/unRARed/rbpkr/actions/workflows/ruby.yml/badge.svg)](https://github.com/unRARed/rbpkr/actions/workflows/ruby.yml)

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

Running the Server
------------------

<img align="left" src="https://raw.githubusercontent.com/unRARed/rbpkr/main/hand_2.jpg">

- First `bundle install`
- Then run `rackup`.
  - This will run a server from `http://127.0.0.1:9292`
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

**Conventions**

- the `@state` instance variable should only contain YAML-seriazable
  data and be translated to more meaningful data as part of the
  initialization process.

<img align="left" src="https://raw.githubusercontent.com/unRARed/rbpkr/main/hand_back.jpg">

