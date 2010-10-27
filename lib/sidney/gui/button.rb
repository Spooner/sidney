# encoding: utf-8

require_relative 'label'

module Sidney
module Gui
class Button < Label
  DEFAULT_BACKGROUND_COLOR = Color.rgb(100, 100, 100)
  DEFAULT_BORDER_COLOR = Color.rgb(150, 150, 150)
  DEFAULT_COLOR = Color.rgb(255, 255, 255)

  HOVER_COLOR = Color.rgb(150, 150, 150)
  DISABLED_COLOR = Color.rgb(150, 150, 150)

  def initialize(parent, options = {}, &block)
    options = {
      color: DEFAULT_COLOR.dup,
      background_color: DEFAULT_BACKGROUND_COLOR.dup,
      border_color: DEFAULT_BORDER_COLOR.dup,
    }.merge! options

    super(parent, options)

    update_colors
  end

  public
  def clicked_left_mouse_button(sender, x, y)
    # TODO: Play click sound?
    nil
  end

  public
  def enabled=(value)
    super(value)
    update_colors

    value
  end

  protected
  def update_colors
    @background_color = if @mouse_over and enabled?
      HOVER_COLOR
    else
      DEFAULT_BACKGROUND_COLOR
    end

    @color = if enabled?
      DEFAULT_COLOR
    else
      DISABLED_COLOR
    end

    nil
  end

  public
  def enter(sender)
    @mouse_over = true
    update_colors

    nil
  end

  public
  def leave(sender)
    @mouse_over = false
    update_colors

    nil
  end
end
end
end