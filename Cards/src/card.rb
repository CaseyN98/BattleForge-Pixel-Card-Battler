require 'gosu'

# Auto-build CARD_ART registry by scanning assets/cards folder
CARD_ART = {}
Dir["assets/cards/*.png"].each do |path|
  id = File.basename(path, ".png").to_i
  CARD_ART[id] = path
end

class Card
  attr_reader :id, :name, :attack, :defense, :rarity, :abilities, :image, :element, :flavor_text
  attr_accessor :x, :y

  def initialize(data)
    # JSON.parse returns string keys by default
    @id          = data["id"]
    @name        = data["name"] || "Unknown"
    @attack      = data["attack"] || 0
    @defense     = data["defense"] || 0
    @rarity      = (data["rarity"] || "common").downcase.strip
    @abilities   = data["abilities"] || []
    @element     = data["element"] || nil
    @flavor_text = data["flavor_text"] || ""

    art_path = CARD_ART[@id]
    if art_path && File.exist?(art_path)
      @image = Gosu::Image.new(art_path)
    else
      @image = nil
    end

    @x = 0
    @y = 0
  end

  # === Helpers ===
  def defense_with_bonus(bonus = 0)
    @defense + bonus
  end

  def to_h
    {
      "id"          => @id,
      "name"        => @name,
      "attack"      => @attack,
      "defense"     => @defense,
      "rarity"      => @rarity,
      "abilities"   => @abilities,
      "element"     => @element,
      "flavor_text" => @flavor_text
    }
  end

  # === Drawing ===
def draw(font, scale: 1.0, z: 1)
  card_w = 32 * scale
  card_h = 32 * scale
  draw_x = @x
  draw_y = @y - card_h

  if @image
    @image.draw(draw_x, draw_y, z, scale, scale)
  else
    Gosu.draw_rect(draw_x, draw_y, card_w, card_h, Gosu::Color::GRAY, z)
  end

  # Tighter spacing for vertical layout
  name_offset   = card_h + (4 * scale)
  stats_offset  = card_h + (16 * scale)

  font.draw_text(@name, draw_x, draw_y + name_offset, z + 1, 1.0, 1.0, Gosu::Color::WHITE)

  # ATK and DEF closer together
  font.draw_text(@attack.to_s, draw_x, draw_y + stats_offset, z + 1, 1.0, 1.0, Gosu::Color::RED)
  font.draw_text(@defense.to_s, draw_x + (26 * scale), draw_y + stats_offset, z + 1, 1.0, 1.0, Gosu::Color::GREEN)
end
end


