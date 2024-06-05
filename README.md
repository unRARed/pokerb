PokeRb
======

Play Texas Holdem' Poker with your friends... even if they can't deal for shit.

![Community Cards](https://raw.githubusercontent.com/unRARed/pokerb/main/community-cards.jpg)

Using the App
-------------

<img align="left" src="https://raw.githubusercontent.com/unRARed/pokerb/main/hand.jpg">

- Run `bin/server` from machine on local network
- Access `YOUR_SERVERS_IP:5000` on tablet / shared device
- Create a new game
- Scan QR code from another device to join

Development
-----------

- `rake test` runs the test suite

Conventions
-----------

- the `@state` instance variable should only contain YAML-seriazable
  data and be translated to more meaningful data as part of the
  initialization process.
