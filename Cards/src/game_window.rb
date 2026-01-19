# src/game_window.rb
require "gosu"
require "json"
require "battle_manager"
require "card"
require "player"
require "bot"
require "main_menu"
require "deck_select"
require "draft_manager"

class GameWindow < Gosu::Window
  attr_accessor :state, :player_deck, :opponent_deck, :draft_manager

  CARD_W = 120
  CARD_H = 160 
  
  def card_image_top(y)
    y - CARD_H * 3.0  # scale 3.0
  end

  def initialize
    super(Gosu.screen_width, Gosu.screen_height, fullscreen: true)
    self.caption = "BattleForge: Pixel Card Arena"

    @state = :menu
    @menu  = MainMenu.new(self)
    @draft_manager = nil

    @font = Gosu::Font.new(24)

    @player1 = nil
    @player2 = nil
    @battle  = nil

    @p1_choices = []
    @p2_choices = []

    @p1_positions = []
    @p2_positions = []

    @p1_card = nil
    @p2_card = nil

    @center_p1 = nil
    @center_p2 = nil

    @battle_phase = :selecting
    @battle_timer = 0

    @last_message = ""
    @hovered_card = nil
  end

  def draw
    case @state
    when :menu
      @menu.draw
    when :deck_select
      @deck_select.draw
    when :draft
      draw_draft
    when :battle
      draw_battle
    when :end
      draw_end_screen
    end
  end
    
  # === Draft Mode ===
  def start_draft
    pool = JSON.parse(File.read(File.join(__dir__, "cards.json"))).map { |c| Card.new(c) }
    @draft_manager = DraftManager.new(pool)
    @state = :draft
  end

  def draw_draft
    return unless @draft_manager
    rarity = @draft_manager.current_rarity
    return unless rarity

    limit  = @draft_manager.rarity_limits[rarity]
    picked = @draft_manager.drafted.count { |c| c.rarity == rarity }

    @font.draw_text("Draft #{rarity.capitalize} cards (#{picked}/#{limit})", 50, 50, 1)

    pool = @draft_manager.current_pool
    @hovered_card = nil

    pool.each_with_index do |card, i|
      x = 50 + (i % 5) * 150
      y = 150 + (i / 5) * 180

      # Hover detection
      if mouse_x.between?(x, x + CARD_W) && mouse_y.between?(y, y + CARD_H)
        @hovered_card = card
        Gosu.draw_rect(x - 2, y - 2, CARD_W + 4, CARD_H + 4, Gosu::Color::YELLOW, 0)
      end

      Gosu.draw_rect(x, y, CARD_W, CARD_H, Gosu::Color::GRAY, 0)
      @font.draw_text(card.name, x + 10, y + 10, 1)
      @font.draw_text("ATK #{card.attack}", x + 10, y + 40, 1)
      @font.draw_text("DEF #{card.defense}", x + 10, y + 60, 1)
    end

    draw_card_info(@hovered_card) if @hovered_card
  end

  def save_temp_deck(cards, filename)
    path = File.join(__dir__, filename)
    File.write(path, JSON.pretty_generate(cards.map(&:to_h)))
    path
  end

  def choose_deck(who)
    @deck_select = DeckSelect.new(self, who)
    @state = :deck_select
  end

  # === Battle ===

  def prepare_round
    return if @battle.battle_over?

    @p1_choices = @player1.deal_hand(3)
    @p2_choices = @player2.deal_hand(3)

    @p1_card = nil
    @p2_card = nil

    @battle_phase = :selecting
    compute_layout
  end

  def compute_layout
    gap = CARD_H * 1.15

    # Player 1 vertical hand (left)
    @p1_positions = []
    x_left = width * 0.05
    y_start = height * 0.25

    3.times do |i|
      @p1_positions << { x: x_left, y: y_start + i * gap }
    end

    # Player 2 vertical hand (right)
    @p2_positions = []
    x_right = width * 0.95 - CARD_W
    y_start2 = height * 0.25

    3.times do |i|
      @p2_positions << { x: x_right, y: y_start2 + i * gap }
    end

    # Center battle positions
    @center_p1 = { x: width * 0.50 - CARD_W / 2, y: height * 0.35 }
    @center_p2 = { x: width * 0.50 - CARD_W / 2, y: height * 0.65 }
  end

  def start_battle
    return unless @player_deck && @opponent_deck

    player_cards   = JSON.parse(File.read(@player_deck)).map { |c| Card.new(c) }
    opponent_cards = JSON.parse(File.read(@opponent_deck)).map { |c| Card.new(c) }

    @player1 = Player.new("Player", player_cards)
    @player2 = Bot.new("Opponent", opponent_cards)
    @battle  = BattleManager.new(@player1, @player2)

    @state = :battle
    prepare_round
  end

  def update
    case @battle_phase
    when :moving_to_center
      @p1_card.x = @center_p1[:x]
      @p1_card.y = @center_p1[:y]
      @p2_card.x = @center_p2[:x]
      @p2_card.y = @center_p2[:y]

      if Gosu.milliseconds - @battle_timer > 800
        @battle_phase = :pause_before_result
        @battle_timer = Gosu.milliseconds
      end
    when :pause_before_result
      if Gosu.milliseconds - @battle_timer > 1000
        resolve_battle
      end
    end
  end

  def draw_battle
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK, 0)
    @hovered_card = nil
    
    scaled_w = CARD_W - 20
    scaled_h = 100

    # Draw P2 hand (right)
    @p2_choices.each_with_index do |card, i|
      next if @p2_card == card
      pos = @p2_positions[i]
      card.x = pos[:x]
      card.y = pos[:y]
      
      image_x = pos[:x]
      image_y = pos[:y] - scaled_h
      if mouse_x.between?(image_x, image_x + scaled_w) && mouse_y.between?(image_y, image_y + scaled_h)
        @hovered_card = card
      end
      card.draw(@font, scale: 3.0)
    end

    # Draw P1 hand (left)
    @p1_choices.each_with_index do |card, i|
      next if @p1_card == card
      pos = @p1_positions[i]
      card.x = pos[:x]
      card.y = pos[:y]
      
      image_x = pos[:x]
      image_y = pos[:y] - scaled_h
      if mouse_x.between?(image_x, image_x + scaled_w) && mouse_y.between?(image_y, image_y + scaled_h)
        @hovered_card = card
        Gosu.draw_rect(image_x - 1, image_y - 1, scaled_w + 2, scaled_h + 2, Gosu::Color::YELLOW, 0)
      end
      card.draw(@font, scale: 3.0)
    end

    # Center cards
    [@p1_card, @p2_card].compact.each do |card|
      pos = (card == @p1_card ? @center_p1 : @center_p2)
      card.x = pos[:x]
      card.y = pos[:y]
      
      image_y = pos[:y] - scaled_h
      if mouse_x.between?(pos[:x], pos[:x] + scaled_w) && mouse_y.between?(image_y, image_y + scaled_h)
        @hovered_card = card
      end
      card.draw(@font, scale: 3.0)
    end

    # UI labels
    @font.draw_text("Cards Left: #{@player1.hand.size + @player1.deck.size}", 50, height - 80, 1)
    @font.draw_text("Cards Left: #{@player2.hand.size + @player2.deck.size}", width - 250, height - 80, 1)
    @font.draw_text(@last_message, width * 0.20, height * 0.15, 1, 1.0, 1.0, Gosu::Color::YELLOW)
    @font.draw_text(@player1.name, 50, height - 40, 1, 1.0, 1.0, Gosu::Color::RED)
    @font.draw_text(@player2.name, width - 200, height - 40, 1, 1.0, 1.0, Gosu::Color::BLUE)

    draw_card_info(@hovered_card) if @hovered_card
  end

  def draw_card_info(card)
    return unless card
    
    tw, th = 280, 180
    tx, ty = mouse_x + 25, mouse_y + 25
    tx = width - tw - 10 if tx + tw > width
    ty = height - th - 10 if ty + th > height
    
    Gosu.draw_rect(tx, ty, tw, th, Gosu::Color.new(0xee_222222), 10)
    
    title_color = case card.rarity.to_s.downcase
                  when "common"    then Gosu::Color::GREEN
                  when "rare"      then Gosu::Color.new(0xff_0000ff) # Blue
                  when "legendary" then Gosu::Color.new(0xff_ff8c00) # Orange
                  else Gosu::Color::CYAN
                  end
    
    @font.draw_text(card.name, tx + 15, ty + 15, 11, 1.1, 1.1, title_color)
    @font.draw_text(card.rarity.capitalize, tx + 15, ty + 45, 11, 0.8, 0.8, Gosu::Color::GRAY)
    
    @font.draw_text("ATK: #{card.attack}", tx + 15, ty + 75, 11, 1.0, 1.0, Gosu::Color::RED)
    @font.draw_text("DEF: #{card.defense}", tx + 110, ty + 75, 11, 1.0, 1.0, Gosu::Color::GREEN)
    
    @font.draw_text("Element: #{card.element || 'None'}", tx + 15, ty + 105, 11, 0.9, 0.9, Gosu::Color::YELLOW)
    
    if card.flavor_text && !card.flavor_text.empty?
      wrapped = card.flavor_text.scan(/.{1,35}(\s|$)/).map(&:first).join("\n")
      @font.draw_text(wrapped, tx + 15, ty + 135, 11, 0.7, 0.7, Gosu::Color::WHITE)
    end
  end

  def button_down(id)
    case @state
    when :menu then @menu.click(mouse_x, mouse_y) if id == Gosu::MsLeft
    when :deck_select
      @deck_select.click(mouse_x, mouse_y) if id == Gosu::MsLeft
      @deck_select.scroll_up if [Gosu::KB_UP, Gosu::MS_WHEEL_UP].include?(id)
      @deck_select.scroll_down if [Gosu::KB_DOWN, Gosu::MS_WHEEL_DOWN].include?(id)
    when :draft
      handle_draft_click(id)
    when :battle then handle_battle_click(id)
    when :end then handle_end_click(id)
    end
    close if id == Gosu::KB_ESCAPE
  end

  def handle_draft_click(id)
    return unless id == Gosu::MsLeft
    pool = @draft_manager.current_pool
    pool.each_with_index do |card, i|
      x = 50 + (i % 5) * 150
      y = 150 + (i / 5) * 180
      if mouse_x.between?(x, x + CARD_W) && mouse_y.between?(y, y + CARD_H)
        @draft_manager.pick(i)
        if @draft_manager.complete?
          @player_deck   = save_temp_deck(@draft_manager.drafted, "player_draft.json")
          @opponent_deck = Dir["decks/*.json"].sample
          @state = :menu
        end
      end
    end
  end

  def handle_battle_click(id)
    return unless id == Gosu::MsLeft && @battle_phase == :selecting
    chosen_index = nil
    @p1_positions.each_with_index do |pos, i|
      image_y = pos[:y] - 100
      if mouse_x.between?(pos[:x], pos[:x] + 100) && mouse_y.between?(image_y, image_y + 100)
        chosen_index = i; break
      end
    end
    return unless chosen_index
    @p1_card = @player1.choose_card(chosen_index)
    @p2_card = @player2.choose_card(rand(@p2_choices.size))
    @battle_phase, @battle_timer = :moving_to_center, Gosu.milliseconds
  end

  def handle_end_click(id)
    return unless id == Gosu::MsLeft
    if mouse_x.between?(300, 500) && mouse_y.between?(350, 400) then reset_game
    elsif mouse_x.between?(300, 500) && mouse_y.between?(420, 470) then close
    end
  end

  def resolve_battle
    @last_message = @battle.resolve(@p1_card, @p2_card)[1]
    [@player1, @player2].each(&:reset_turn_state)
    if @battle.battle_over?
      winner = @battle.winner
      @last_message = "#{winner.name} wins!" if winner
      @state = :end
    else
      @battle_phase = :selecting
      prepare_round
    end
  end

  def draw_end_screen
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK, 0)
    @font.draw_text("Game Over!", 320, 200, 1, 1.5, 1.5, Gosu::Color::RED)
    @font.draw_text(@last_message, 250, 250, 1, 1.0, 1.0, Gosu::Color::WHITE)
    Gosu.draw_rect(300, 350, 200, 50, Gosu::Color::GRAY, 0)
    @font.draw_text("Play Again", 340, 365, 1)
    Gosu.draw_rect(300, 420, 200, 50, Gosu::Color::GRAY, 0)
    @font.draw_text("Quit", 370, 435, 1)
  end

  def reset_game
    @state, @player1, @player2, @battle = :menu, nil, nil, nil
    @p1_card, @p2_card, @last_message, @draft_manager = nil, nil, "", nil
  end
end

GameWindow.new.show