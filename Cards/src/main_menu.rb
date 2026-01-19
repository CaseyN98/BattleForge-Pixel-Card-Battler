require 'gosu'

Button = Struct.new(:label, :x, :y, :width, :height, :action, :hover)

class MainMenu
  def initialize(window)
    @window = window
    @font = Gosu::Font.new(20)
    @title_font = Gosu::Font.new(48)
    @buttons = build_buttons
  end

  def build_buttons
    base_x = (@window.width / 2) - 150
    [
      Button.new("Choose Player Deck",   base_x, 180, 300, 55, -> { @window.choose_deck(:player) }, false),
      Button.new("Choose Opponent Deck", base_x, 260, 300, 55, -> { @window.choose_deck(:opponent) }, false),
      Button.new("Draft Deck",           base_x, 340, 300, 55, -> { @window.start_draft }, false),
      Button.new("Start Battle",         base_x, 420, 300, 55, -> { @window.start_battle }, false)
    ]
  end

  def draw
    draw_background
    draw_title
    draw_buttons
  end

  def draw_background
    # Simple vertical gradient
    top_color = Gosu::Color.argb(0xff1e1e2f)
    bottom_color = Gosu::Color.argb(0xff0d0d14)

    Gosu.draw_quad(
      0, 0, top_color,
      @window.width, 0, top_color,
      0, @window.height, bottom_color,
      @window.width, @window.height, bottom_color,
      0
    )
  end

  def draw_title
    title = "BattleForge: Pixel Card Arena"
    text_width = @title_font.text_width(title)
    x = (@window.width - text_width) / 2
    y = 80

    # Soft shadow
    @title_font.draw_text(title, x + 3, y + 3, 1, 1, 1, Gosu::Color::BLACK)
    @title_font.draw_text(title, x, y, 1, 1, 1, Gosu::Color::YELLOW)
  end

  def draw_buttons
    @buttons.each do |btn|
      color = btn.hover ? Gosu::Color::GRAY : Gosu::Color::argb(0xff444444)
      border = Gosu::Color::argb(0xff888888)

      # Button background
      Gosu.draw_rect(btn.x, btn.y, btn.width, btn.height, color, 1)

      # Border
      Gosu.draw_rect(btn.x, btn.y, btn.width, 2, border, 2)
      Gosu.draw_rect(btn.x, btn.y + btn.height - 2, btn.width, 2, border, 2)

      # Text centered
      text_x = btn.x + (btn.width - @font.text_width(btn.label)) / 2
      text_y = btn.y + (btn.height - 20) / 2

      @font.draw_text(btn.label, text_x, text_y, 3, 1, 1, Gosu::Color::WHITE)
    end
  end

  def update_hover(mx, my)
    @buttons.each do |btn|
      btn.hover = mx.between?(btn.x, btn.x + btn.width) &&
                  my.between?(btn.y, btn.y + btn.height)
    end
  end

  def click(mx, my)
    @buttons.each do |btn|
      if mx.between?(btn.x, btn.x + btn.width) && my.between?(btn.y, btn.y + btn.height)
        btn.action.call
      end
    end
  end
end