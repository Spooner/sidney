# encoding: utf-8

require_relative 'composite'
require_relative 'button'

module Sidney
module Gui
class MenuPane < Composite
  # An item within the menu.
  class Item < Button
    DEFAULT_BORDER_COLOR = Color.rgba(0, 0, 0, 0)
    attr_reader :value, :shortcut

    public
    # @param [any] value Value if the user picks this item
    # @option options [Boolean] :enabled (true)
    # @option options [String] :shortcut ('')
    def initialize(parent, value, options = {})
      options = {
        enabled: true,
        border_color: DEFAULT_BORDER_COLOR,
      }.merge! options

      @value = value
      @enabled = [true, false].include?(options[:enabled]) ? options[:enabled] : true
      @shortcut = options[:shortcut] || ''

      super(parent, options)
    end

    protected
    def layout
      super
      rect.width += font.text_width("  #{@shortcut}") unless @shortcut.empty?
      nil
    end

    public
    def draw_foreground
      super
      unless @shortcut.empty?
        font.draw_rel("#{@shortcut}", rect.right - padding_x, y + ((height - font_size) / 2).floor, z, 1, 0, 1, 1, color)
      end

      nil
    end
  end

  class Separator < Item
    DEFAULT_LINE_HEIGHT = 1

    public
    def initialize(parent, options)
      options = {
        enabled: false,
        line_height: DEFAULT_LINE_HEIGHT,
      }.merge! options

      @line_height = options[:line_height]

      super parent, options
    end

    protected
    def layout
      super
      rect.height = @line_height
      nil
    end
  end

  DEFAULT_BACKGROUND_COLOR = Color.rgb(50, 50, 50)

  def index(value); inner_container.index find(value); end
  def size; inner_container.size; end
  def [](index); inner_container[index]; end
  
  public
  def initialize(options = {}, &block)
    options = {
      background_color: DEFAULT_BACKGROUND_COLOR.dup,
      z: Float::INFINITY,
    }.merge! options

    super(nil, VerticalPacker.new(nil, spacing: 0, padding: 0), options)
  end

  public
  def find(value)
    inner_container.find {|c| c.value == value }
  end

  def layout
    super
    max_width = inner_container.each.to_a.map {|c| c.width }.max || 0
    inner_container.each {|c| c.rect.width = max_width }
    nil
  end

  public
  def add_separator(options = {})
    options[:z] = z

    Separator.new(inner_container, options)
  end

  public
  def add_item(value, options = {})
    options[:z] = z
    item = Item.new(inner_container, value, options)

    item.subscribe :left_mouse_button, method(:item_selected)
    item.subscribe :right_mouse_button, method(:item_selected)

    item
  end

  public
  def item_selected(sender, x, y)
    publish(:selected, sender.value)

    $window.game_state_manager.current_game_state.hide_menu

    nil
  end
end
end
end