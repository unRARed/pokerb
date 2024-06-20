PokeRb
======

[![Ruby](https://github.com/unRARed/pokerb/actions/workflows/ruby.yml/badge.svg)](https://github.com/unRARed/pokerb/actions/workflows/ruby.yml)

Play Texas Holdem' Poker with your friends... even if they can't
deal for shit. This is NOT meant for production usage. Any use
of this software is of your own risk. This exists to speed up your
home game card dealing. If you have a cool idea, submit an issue,
or better yet, a PR.

![Community Cards](https://raw.githubusercontent.com/unRARed/pokerb/main/community-cards.jpg)

Using the App
-------------

<img align="left" src="https://raw.githubusercontent.com/unRARed/pokerb/main/hand.jpg">

- Run `rackup -p 5001` (or whatever port you want it on)
  - This uses the first ipv4 ip found for accessing on your LAN
  - Add `POKERB_HOSTNAME=yourdomain.com bin/server` to specify host
  - Or use `DEBUG=1 bin/server` to see debug logging
- Now access `HOST:5000` on tablet / shared device
- Create a new game
- Scan QR code from other device(s) to join the game

Development
-----------

- `rake test` runs the test suite

Conventions
-----------

- the `@state` instance variable should only contain YAML-seriazable
  data and be translated to more meaningful data as part of the
  initialization process.
