require 'json'
require_relative 'game'
require_relative 'player'
require_relative 'card'
require_relative 'bot'
require_relative 'game_window'

def load_deck_from_file(filename)
  JSON.parse(File.read(filename)).map { |c| Card.new(c) }
end

def choose_deck(deck_files, prompt)
  puts "\n#{prompt}"
  deck_files.each_with_index { |file, index| puts "#{index}: #{file}" }
  print "Select by number: "
  input = gets.chomp
  unless input =~ /^\d+$/ && deck_files[input.to_i]
    puts "Invalid selection. Using default: #{deck_files.first}"
    return deck_files.first
  end
  deck_files[input.to_i]
end

def view_deck(deck, title = "📦 Deck Preview")
  puts "\n#{title}"
  deck.each_with_index do |card, i|
    puts "#{i + 1}. #{card.name} (#{card.rarity}) — ATK: #{card.attack}, DEF: #{card.defense}"
    puts "   Element: #{card.element}" if card.element
    puts "   Abilities: #{card.abilities.join(', ')}" unless card.abilities.empty?
    puts "   \"#{card.flavor_text}\"" unless card.flavor_text.empty?
  end
end

def draft_player_deck(full_card_pool)
  puts "\n🧠 Let's draft your deck!"
  rarity_limits = { "common" => 5, "rare" => 4, "legendary" => 1 }
  draft_pool_sizes = { "common" => 16, "rare" => 16, "legendary" => 6 }

  grouped = full_card_pool.group_by { |card| card.rarity.downcase.strip }
  drafted = []

  rarity_limits.each do |rarity, limit|
    pool = grouped[rarity]&.shuffle || []
    draft_pool = pool.take([draft_pool_sizes[rarity], pool.size].min)

    puts "\n#{rarity.capitalize} Draft Pool:"
    draft_pool.each_with_index do |card, i|
      puts "#{i}: #{card.name} (ATK #{card.attack} / DEF #{card.defense})"
    end

    picked = []
    while picked.size < [limit, draft_pool.size].min
      print "Pick #{limit - picked.size} more #{rarity} card(s): "
      input = gets.chomp
      unless input =~ /^\d+$/ && draft_pool[input.to_i]
        puts "Invalid or duplicate selection. Try again."
        next
      end
      selected = draft_pool[input.to_i]
      if !picked.include?(selected)
        picked << selected
        puts "✓ Added #{selected.name}"
      else
        puts "Invalid or duplicate selection. Try again."
      end
    end

    drafted.concat(picked)
  end

  drafted.shuffle
end

# 🌌 Lore intro
puts "\n🌌 A shadow stirs in the LoopForge..."
puts "You are a Seeker, bound to the sigil rings. Choose your path wisely."

deck_files = Dir.glob("decks/*.json")
abort("❌ No decks found in 'decks/'") if deck_files.empty?

opponent_file = choose_deck(deck_files, "Available Opponent Decks:")
opponent_name = File.basename(opponent_file, ".json").capitalize
opponent_deck = load_deck_from_file(opponent_file).sample(10).shuffle
puts "\n🧙 Opponent '#{opponent_name}' selected."

card_pool_data = JSON.parse(File.read("cards.json"))
full_card_pool = card_pool_data.map { |c| Card.new(c) }

puts "\nChoose how you'd like to build your deck:"
puts "1. Use a predefined deck"
puts "2. Draft your own deck"
print "> "
build_mode = gets.to_i

player_deck = if build_mode == 1
  player_file = choose_deck(deck_files, "Available Player Decks:")
  load_deck_from_file(player_file)
else
  draft_player_deck(full_card_pool)
end

print "\nWould you like to view your deck before battle? (Y/N): "
response = gets.chomp.strip.downcase
view_deck(player_deck, "📦 Your Deck Preview") if response == "y"

player_deck.shuffle!
@p1 = Player.new("You", player_deck)
@p2 = Bot.new(opponent_name, opponent_deck)

puts "\nChoose game mode:"
puts "1. CLI"
puts "2. Graphical"
print "> "
mode = gets.to_i

if mode == 1
  Game.new(@p1, @p2).start
else
  GameWindow.new(@p1, @p2).show
end

