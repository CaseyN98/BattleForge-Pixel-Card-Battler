class BattleManager
  attr_reader :p1, :p2, :log

  def initialize(p1, p2)
    @p1, @p2 = p1, p2
    @log = []
    @round = 0
  end

  # === Resolve a battle between two chosen cards ===
def resolve(card1, card2)
  return [:none, "❌ No battle: missing card(s)."] unless card1 && card2

  p1_kills_p2 = card1.attack >= card2.defense
  p2_kills_p1 = card2.attack >= card1.defense

  if p1_kills_p2 && p2_kills_p1
    @p1.hand.delete(card1)
    @p2.hand.delete(card2)
    msg = "Both cards are defeated!"
    return [:both_die, msg]

  elsif p1_kills_p2
    @p2.hand.delete(card2)
    msg = "#{@p1.name}'s #{card1.name} defeats #{@p2.name}'s #{card2.name}!"
    return [:p1_win, msg]

  elsif p2_kills_p1
    @p1.hand.delete(card1)
    msg = "#{@p2.name}'s #{card2.name} defeats #{@p1.name}'s #{card1.name}!"
    return [:p2_win, msg]

  else
    msg = "Neither card could defeat the other."
    return [:stalemate, msg]
  end
end

  # === Logging ===
  def log!(msg)
    @log << msg
    puts msg
    write_log_to_file(msg)
    msg
  end

  def write_log_to_file(msg)
    File.open("decks/battle_log.txt", "a") do |f|
      f.puts "[Round #{@round}] [#{Time.now}] #{msg}"
    end
  rescue => e
    puts "⚠️ Could not write battle log: #{e.message}"
  end

  # === Battle State ===
  def battle_over?
    !@p1.alive? || !@p2.alive?
  end

  def winner
    return @p1 if @p1.alive? && !@p2.alive?
    return @p2 if @p2.alive? && !@p1.alive?
    nil
  end
end