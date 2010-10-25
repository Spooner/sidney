# encoding: utf-8

require_relative 'container'

module Sidney
module Gui
  class Slider < Container
    # @private
    class Handle < Element
      DEFAULT_BACKGROUND_COLOR = Color.rgb(255, 0, 0)
      DEFAULT_BORDER_COLOR = Color.rgba(0, 0, 0, 0)

      protected
      def initialize(parent, options = {}, &block)
        options = {
          background_color: DEFAULT_BACKGROUND_COLOR.dup,
          border_color: DEFAULT_BORDER_COLOR.dup,
        }.merge! options

        super parent, options
      end
    end

    DEFAULT_BACKGROUND_COLOR = Color.rgba(0, 0, 0, 0)
    DEFAULT_BORDER_COLOR = Color.rgba(0, 0, 0, 0)
    DEFAULT_GROOVE_COLOR = Color.rgb(200, 200, 200)
    DEFAULT_HANDLE_COLOR = Color.rgb(255, 0, 0)

    attr_reader :value, :range

    # @option options [Range] :range (0..1.0)
    # @option options [Range] :value (minimum of :range)
    protected
    def initialize(parent, options = {}, &block)
      options = {
        range: 0..1.0,
        height: 25,
        background_color: DEFAULT_BACKGROUND_COLOR.dup,
        border_color: DEFAULT_BORDER_COLOR.dup,
        groove_color: DEFAULT_GROOVE_COLOR.dup,
        handle_color: DEFAULT_HANDLE_COLOR.dup,
      }.merge! options

      @range = options[:range]
      @groove_color = options[:groove_color]

      super(parent, options)

      @handle = Handle.new(self, width: (height / 2 - padding_x), height: height - padding_y * 2,
                           background_color: options[:handle_color])

      self.value = options[:value] ? options[:value] : @range.min
    end

    protected
    def layout
      nil
    end

    public
    def value=(value)
      raise ArgumentError, "value (#{value}} must be within range #{@range}" unless @range.include? value
      @value = value
      @handle.x = x + padding_x + ((width - padding_x * 2) * ((value - @range.min) / (@range.max - @range.min).to_f) - @handle.width / 2).round
      publish :changed, value

      @value
    end

    public
    def tip
      "#{super}: #{@value}"
    end

    public
    def draw_background
      super
      $window.draw_box x + padding_x, y + padding_y, width - padding_x * 2, height - padding_y * 4, z, nil, @groove_color
      nil
    end

    public
    def left_mouse_button(sender, x, y)
      value = (((x - self.x - padding_x) / (width - padding_x * 2)) * (@range.max - @range.min) + @range.min).to_i
      self.value = [[value, @range.max].min, @range.min].max
      @mouse_down = true

      nil
    end

    public
    def hit_element(x, y)
      if @handle.hit?(x, y)
        self # TODO: should pass this to the handle, so it can be dragged.
      elsif hit?(x, y)
        self
      else
        nil
      end
    end
  end
end
end