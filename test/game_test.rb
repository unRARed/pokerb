require_relative 'test_helper'

class GameTest < PokerTest
  let(:subject) { Poker::Game.new }

  def test_initialize
    assert_equal(
      [:deck, :players, :hands, :button_index],
      subject.state.keys
    )
  end

  def test_add_player
    subject.add_player
    assert_equal 1, subject.state[:players].size
  end

  def test_determine_button
    9.times{ subject.add_player }
    subject.determine_button

    assert subject.state[:players].
      all?{ |p| p.state[:hole_cards].present? }
    refute_nil subject.state[:button_index]
  end

  def test_players_in_turn_order
    4.times{ subject.add_player }
    subject.determine_button

    player_with_button =
      subject.state[:players][subject.state[:button_index]]
    assert_equal player_with_button,
      subject.players_in_turn_order[-1]
  end

  def test_player_in_small_blind
    4.times{ subject.add_player }
    subject.determine_button

    assert_equal subject.player_in_small_blind,
      subject.players_in_turn_order[0]
  end

  def test_player_in_big_blind
    4.times{ subject.add_player }
    subject.determine_button

    assert_equal subject.player_in_big_blind,
      subject.players_in_turn_order[1]
  end

  def test_ready?
    refute subject.ready?
    subject.add_player
    refute subject.ready?
    subject.add_player
    refute subject.ready?
    subject.determine_button
    assert subject.ready?
  end

  # TODO: determine how to target player
  # def test_remove_player
  # end
end
