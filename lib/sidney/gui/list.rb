# encoding: utf-8

require_relative 'container'

module Sidney
module Gui
  class List < Composite
    # @private
    class Item < Button
      class Group < RadioButton::Group
      end
      # TODO: Need to inherit from RadioButton, but it doesn't display anything.
    end

    DEFAULT_BACKGROUND_COLOR = Color.rgb(200, 200, 200)
    DEFAULT_BORDER_COLOR = Color.rgb(255, 255, 255)

    def size; @packer.size; end
    def clear; @packer.clear; end

    protected
    def initialize(parent, options = {})
      options = {
        background_color: DEFAULT_BACKGROUND_COLOR,
        border_color: DEFAULT_BORDER_COLOR,
      }.merge! options

      super parent, Item::Group.new(nil), options

      @packer = VerticalPacker.new(inner_container, spacing: 0)
    end

    # @param [String] text
    # @option options [Gosu::Image] :icon
    public
    def add_item(options = {})
      Item.new(@packer, options)
    end
  end
end
end