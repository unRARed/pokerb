require "spec_helper"

RSpec.describe "Deck" do
  let(:subject) { Poker::Deck.new }

  it "initialize" do
    expect(subject.state[:stack].size).to eq(0)
    expect(subject.state[:discarded].size).to eq(0)
    expect(subject.state[:community].size).to eq(0)
    expect(subject.phase).to eq(:deal)
  end

  context "(with cards)" do
    let(:subject) do
      Poker::Deck.
        new stack: Poker::Deck.fresh.map{ |c| c.tuple }
    end

    it ".burn" do
      burn_card = subject.state[:stack].last

      subject.burn

      expect(subject.to_hash[:stack].size).to eq(51)
      expect(subject.to_hash[:discarded].size).to eq(1)
      expect(subject.to_hash[:discarded]).
        to include(burn_card.tuple)

      next_burn = subject.state[:stack].last

      subject.burn

      expect(subject.to_hash[:stack].size).to eq(50)
      expect(subject.to_hash[:discarded].size).to eq(2)
      expect(subject.to_hash[:discarded]).
        to include(next_burn.tuple)
    end

    it ".draw" do
      drawn_card = subject.state[:stack].first

      subject.draw

      expect(subject.to_hash[:stack].size).to eq(51)
      expect(subject.to_hash[:discarded].size).to eq(0)
      expect(subject.to_hash[:community].size).to eq(0)

      next_draw = subject.state[:stack].first

      subject.draw

      expect(subject.to_hash[:stack].size).to eq(50)
      expect(subject.to_hash[:discarded].size).to eq(0)
      expect(subject.to_hash[:community].size).to eq(0)
    end

    it "shuffle" do
      original_stack = subject.state[:stack]
      subject.shuffle

      expect(subject.to_hash[:stack].size).to eq(52)
      expect(subject.to_hash[:discarded].size).to eq(0)
      expect(subject.to_hash[:community].size).to eq(0)
    end

    it ".to_s" do
      expect(subject.to_s).
        to eq("2c 3c 4c 5c 6c 7c 8c 9c Tc Jc Qc Kc Ac 2d 3d 4d 5d 6d 7d 8d 9d Td Jd Qd Kd Ad 2h 3h 4h 5h 6h 7h 8h 9h Th Jh Qh Kh Ah 2s 3s 4s 5s 6s 7s 8s 9s Ts Js Qs Ks As")
    end
  end
end
