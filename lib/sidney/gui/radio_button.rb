# encoding: utf-8

require_relative 'button'
require_relative 'packer'

module Sidney
module Gui
  class RadioButton < Button
    class Group < Packer
      attr_reader :selected

      def value; @selected ? @selected.value : nil; end

      protected
      # @example
      #   RadioButton::Group.new(packer) do |group|
      #     HorizontalPacker.new(group) do |packer|
      #       RadioButton.new(packer, 1, text: '1' checked: true)
      #       RadioButton.new(packer, 2, text: '2')
      #       group.subscribe :changed do |sender, value|
      #         puts value
      #       end
      #     end
      #    end
      def initialize(parent, options = {}, &block)
        options = {
          padding_x: 0,
          padding_y: 0
        }.merge! options

        super(parent, options)

        @selected = nil
        @buttons = []
      end

      public
      def add_button(button)
        @buttons.push button
        button_checked button if button.checked?

        nil
      end

      # @param [RadioButton] button
      public
      def button_checked(button)
        @selected.send :uncheck if @selected

        @selected = button

        publish :changed, @selected.value

        nil
      end

      public
      # @example
      #   RadioButton::Group.new(packer) do |group|
      #     HorizontalPacker.new(group) do |packer|
      #       RadioButton.new(packer, 1, text: '1')
      #       RadioButton.new(packer, 2, text: '2')
      #       group.value = 2
      #     end
      #    end
      #
      #   # later
      #   group.value = 1
      def value=(value)
        button = @buttons.find { |b| b.value = value }

        raise "Group does not contain a RadioButton with this value (#{value})" unless button

        button_checked(button) unless button.checked?

        button
      end
    end

    DEFAULT_BORDER_COLOR_CHECKED = Color.new(255, 0, 255)
    DEFAULT_BORDER_COLOR_UNCHECKED = Color.new(50, 50, 50)

    attr_reader :group, :value

    def checked?; @checked; end

    protected
    def initialize(parent, value, options = {}, &block)
      options = {
        checked: false,
        border_color_checked: DEFAULT_BORDER_COLOR_CHECKED.dup,
        border_color_unchecked: DEFAULT_BORDER_COLOR_UNCHECKED.dup
      }.merge! options

      @checked = options[:checked]
      @value = value

      super(parent, options)

      @border_color_checked = options[:border_color_checked] || @border_color
      @border_color_unchecked = options[:border_color_unchecked] || @border_color
      add_to_group

      @border_color = checked? ? @border_color_checked : @border_color_unchecked
    end

    protected
    def add_to_group
      container = parent
      while container
        break if container.is_a? Group
        container = container.parent
      end

      raise "#{self.class.name} must be placed inside a group element" unless container

      @group = container
      @group.add_button self
      nil
    end

    public
    def clicked_left_mouse_button(sender, x, y)
      super
      check
      nil
    end

    public
    def check
      @group.button_checked self unless checked?

      @checked = true
      @border_color = @border_color_checked
      publish :checked

      nil
    end

    protected
    # Only ever called from Group!
    def uncheck
      @checked = false
      @border_color = @border_color_unchecked
      publish :unchecked

      nil
    end

    public
    def draw_background
      super

      draw_frame x, y, width, height, z, @border_color

      nil
    end
  end
end
end