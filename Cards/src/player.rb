require_relative 'card'

class Player
  attr_reader :name, :deck, :hand, :discard_pile
  attr_accessor :discard_used

  def initialize(name, cards)
    @name = name
    # Always expect an array of Card objects
    @deck = cards.shuffle
    @hand, @discard_pile = [], []
    @discard_used = false
    replenish_hand
  end

  # === Gameplay Helpers ===

  def passive_defense_bonus
    discard_pile.count { |card| card.abilities.include?(:GodsWill) } * 3
  end

  def discard_card(index)
    return if @discard_used || !index.between?(0, @hand.size - 1)
    card = @hand.delete_at(index)
    @discard_pile << card
    @discard_used = true
    puts "🗑️ #{@name} discarded: #{card.name} [ATK: #{card.attack}, DEF: #{card.defense}]"
    replenish_hand
  end

  def draw_card
    @deck.shift
  end

  def alive?
    @deck.any? || @hand.any?
  end
def choose_card(index)
  return nil unless index.between?(0, @hand.size - 1)
  card = @hand[index]

  replenish_hand
  card
end

def deal_hand(n = 3)
  replenish_hand
  @hand.first([n, @hand.size].min)
end



  def play_card
    return draw_card if hand.empty?

    # Smart discard if hand is weak
    if !discard_used && hand.sum { |c| c.attack + c.defense } < 20
      weakest_index = hand.index(hand.min_by { |c| c.attack + c.defense })
      discard_card(weakest_index)
      return play_card unless hand.empty?
    end

    # Prioritize by rarity, then defense
    rarity_order = ["legendary", "rare", "common"]
    sorted = hand.sort_by { |c| [rarity_order.index(c.rarity), -c.defense] }
    hand.delete(sorted.first)
  end

  def reset_turn_state
    @discard_used = false
  end

  private

  def replenish_hand
    while @hand.size < 3 && @deck.any?
      @hand << draw_card
    end
  end
end

