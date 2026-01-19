class Bot < Player
  def deal_hand(n = 3)
    replenish_hand
    @hand.first([n, @hand.size].min)
  end

  def choose_card(index = nil)
    return nil if hand.empty?

    if index.nil?
      # Bot decides internally
      chosen = if rand < 0.7
                 hand.max_by { |c| c.attack || 0 }
               else
                 hand.sample
               end
      hand.delete(chosen)
      replenish_hand
      chosen
    else
      # Index-based selection
      return nil unless index.between?(0, hand.size - 1)
      card = @hand[index]

      replenish_hand
      card
    end
  end
end
