class DeckSelect
  def initialize(window, who)
    @window = window
    @who = who
    @font = Gosu::Font.new(22)
    @title_font = Gosu::Font.new(36)

    @deck_files = Dir["decks/*.json"]
    @scroll_offset = 0
    @visible_count = 8

    @hover_index = nil
  end

  def draw
    draw_background
    draw_title
    draw_deck_list
    draw_scroll_arrows
  end

  def draw_background
    top = Gosu::Color.argb(0xff1e1e2f)
    bottom = Gosu::Color.argb(0xff0d0d14)

    Gosu.draw_quad(
      0, 0, top,
      @window.width, 0, top,
      0, @window.height, bottom,
      @window.width, @window.height, bottom,
      0
    )
  end

  def draw_title
    title = "Choose #{@who.capitalize} Deck"
    w = @title_font.text_width(title)
    x = (@window.width - w) / 2
    y = 40

    @title_font.draw_text(title, x + 3, y + 3, 1, 1, 1, Gosu::Color::BLACK)
    @title_font.draw_text(title, x, y, 1, 1, 1, Gosu::Color::YELLOW)
  end

  def draw_deck_list
    visible = @deck_files[@scroll_offset, @visible_count] || []

    base_x = (@window.width / 2) - 200
    base_y = 120

    visible.each_with_index do |file, i|
      y = base_y + i * 70

      hovered = (@hover_index == i)
      bg_color = hovered ? Gosu::Color::argb(0xff555555) : Gosu::Color::argb(0xff3a3a3a)
      border_color = Gosu::Color::argb(0xff888888)

      # Card background
      Gosu.draw_rect(base_x, y, 400, 60, bg_color, 1)

      # Top + bottom border
      Gosu.draw_rect(base_x, y, 400, 2, border_color, 2)
      Gosu.draw_rect(base_x, y + 58, 400, 2, border_color, 2)

      name = File.basename(file, ".json")
      text_x = base_x + 20
      text_y = y + 18

      @font.draw_text(name, text_x, text_y, 3, 1, 1, Gosu::Color::WHITE)
    end
  end

  def draw_scroll_arrows
    arrow_color = Gosu::Color::WHITE

    # Up arrow
    @font.draw_text("▲", @window.width - 60, 150, 3, 1, 1, arrow_color)

    # Down arrow
    @font.draw_text("▼", @window.width - 60, 550, 3, 1, 1, arrow_color)
  end

  def update_hover(mx, my)
    @hover_index = nil

    base_x = (@window.width / 2) - 200
    base_y = 120

    visible = @deck_files[@scroll_offset, @visible_count] || []

    visible.each_with_index do |_, i|
      y = base_y + i * 70
      if mx.between?(base_x, base_x + 400) && my.between?(y, y + 60)
        @hover_index = i
      end
    end
  end

  def click(mx, my)
    base_x = (@window.width / 2) - 200
    base_y = 120

    visible = @deck_files[@scroll_offset, @visible_count] || []

    visible.each_with_index do |file, i|
      y = base_y + i * 70
      if mx.between?(base_x, base_x + 400) && my.between?(y, y + 60)
        if @who == :player
          @window.player_deck = file
        else
          @window.opponent_deck = file
        end
        @window.state = :menu
      end
    end

    # Scroll arrows
    if mx.between?(@window.width - 80, @window.width - 20)
      scroll_up if my.between?(150, 200)
      scroll_down if my.between?(550, 600)
    end
  end

  def scroll_up
    @scroll_offset = [@scroll_offset - 1, 0].max
  end

  def scroll_down
    max_offset = [@deck_files.size - @visible_count, 0].max
    @scroll_offset = [@scroll_offset + 1, max_offset].min
  end
end