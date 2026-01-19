class DraftManager
  attr_reader :rarity_limits, :draft_pool_sizes, :grouped, :drafted, :current_rarity

  def initialize(full_card_pool)
    @rarity_limits = { "common" => 5, "rare" => 4, "legendary" => 1 }
    @draft_pool_sizes = { "common" => 16, "rare" => 16, "legendary" => 6 }

    @grouped = full_card_pool.group_by { |c| c.rarity.downcase.strip }
    @drafted = []
    @current_rarity = "common"
    @picked = []
  end
def current_pool
  @current_pool ||= begin
    pool = @grouped[@current_rarity]&.shuffle || []
    pool.take([@draft_pool_sizes[@current_rarity], pool.size].min)
  end
end


  def pick(index)
    pool = current_pool
    card = pool[index]
    return false unless card
    return false if @picked.include?(card)

    @picked << card
    @drafted << card

    if @picked.size >= @rarity_limits[@current_rarity] || @picked.size >= pool.size
      advance_rarity
    end
    true
  end

def advance_rarity
  case @current_rarity
  when "common"    then @current_rarity = "rare"
  when "rare"      then @current_rarity = "legendary"
  when "legendary" then @current_rarity = nil
  end
  @picked = []
  @current_pool = nil
end



  def complete?
    @current_rarity.nil?
  end
end

