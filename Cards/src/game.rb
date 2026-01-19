require 'json'
require_relative 'game_window'
require_relative 'player'
require_relative 'card'
require_relative 'bot'
require_relative 'battle_manager'

RARITY_ICONS = {
  "common"    => "🟢",
  "rare"      => "🟣",
  "legendary" => "🔴"
}

class Game
  def initialize(player1, player2)
    @p1 = player1
    @p2 = player2
    @battle = BattleManager.new(@p1, @p2)
  end

  def clear_screen
    system("clear") || system("cls")
  end

  def show_intro_art
    File.foreach("Loop.txt") { |line| puts line } if File.exist?("Loop.txt")
  end

  def display_card(card)
    return puts "⚠️ No card to display." unless card
    icon = RARITY_ICONS[card.rarity.downcase.strip] || "⚪"
    puts "#{icon} #{card.name} [ATK: #{card.attack}, DEF: #{card.defense}]"
  end

  def choose_card(player)
    loop do
      puts "\n#{player.name}, choose a card to play or discard (e.g. D2 to discard card 2):"
      player.hand.each_with_index do |card, index|
        puts "#{index + 1}. #{card.name} (#{card.rarity}) - ATK: #{card.attack}, DEF: #{card.defense}"
      end
      print "> "
      input = gets.chomp.strip

      if input.match(/^D(\d+)$/i)
        index = input[1..].to_i - 1
        if player.discard_used
          puts "⚠️ Discard already used!"
        else
          player.discard_card(index)
        end
      else
        index = input.to_i - 1
        if index.between?(0, player.hand.size - 1)
          return player.hand.delete_at(index)
        else
          puts "⚠️ Invalid selection."
        end
      end
    end
  end

  def start
    show_intro_art
    puts "Welcome to LoopForge!"
    puts "#{@p1.name} vs. #{@p2.name} — Let the duel begin!"

    while @p1.alive? && @p2.alive? && cards_remaining?(@p1) && cards_remaining?(@p2)
      play_turn
    end

    end_game
  end

  def cards_remaining?(player)
    player.hand.any? || player.deck.any?
  end

  def refill_hand(player)
    player.hand << player.draw_card if player.hand.size < 3 && player.deck.any?
  end

  def reset_turn_state
    @p1.discard_used = false
    @p2.discard_used = false
    @battle.reset_card_effects(@p1.hand + @p2.hand)
  end

  def play_turn
    reset_turn_state
    card1 = choose_card(@p1)
    card2 = @p2.play_card || @p2.draw_card

    clear_screen
    puts "⚔️ #{@p1.name} plays:"
    display_card(card1)
    puts "🛡️ #{@p2.name} counters with:"
    display_card(card2)

    puts "\n— Battle Begins! —"
    puts "\n#{@p1.name} — Cards left: #{@p1.hand.size + @p1.deck.size}"
    puts "#{@p2.name} — Cards left: #{@p2.hand.size + @p2.deck.size}"
    sleep(1)

    @battle.resolve(card1, card2)
    refill_hand(@p1)
    refill_hand(@p2)
  end

  def end_game
    winner =
      if cards_remaining?(@p1) && !cards_remaining?(@p2)
        @p1.name
      elsif cards_remaining?(@p2) && !cards_remaining?(@p1)
        @p2.name
      elsif !cards_remaining?(@p1) && !cards_remaining?(@p2)
        "Draw"
      else
        "Undecided"
      end

    puts "\nGame Over!#{winner == 'Draw' ? ' It’s a draw!' : " Winner: #{winner}"}"
    @battle.write_log_to_file
  end
end

# 🃏 Deck Preview Utility
def preview_decks(deck_files)
  deck_files.each_with_index do |file, index|
    puts "\n#{index}: #{file}"
    cards = JSON.parse(File.read(file)).map { |c| Card.new(c) }
    puts "  — #{cards.size} cards —"
    cards.take(5).each do |card|
      puts "    [ID: #{card.id}] #{card.name} (#{card.rarity}) ATK: #{card.attack}, DEF: #{card.defense}"
      puts "       \"#{card.flavor_text}\"" unless card.flavor_text.empty?
    end
    puts "    ...and #{cards.size - 5} more" if cards.size > 5
  end
end



