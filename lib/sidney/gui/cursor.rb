# encoding: utf-8

require 'chingu'
include Chingu

module Sidney
module Gui
class Cursor < GameObject
  ARROW = 'arrow.png'
  HAND = 'hand.png'

  protected
  def initialize(options = {})
    options = {
      image: Image[ARROW],
      center: 0,
      zorder: Float::INFINITY
    }.merge!(options)

    super(options)

    nil
  end

  # Is the mouse pointer position inside the game window pane?
  public
  def inside_window?
    x >= 0 and y >= 0 and x < $window.width and y < $window.height
  end

  public
  def update
    self.x, self.y = $window.mouse_x, $window.mouse_y

    super

    nil
  end

  public
  def draw
    # Prevent system and game mouse from being shown at the same time.
    super if inside_window? and not $window.needs_cursor?
  end
end
end
end