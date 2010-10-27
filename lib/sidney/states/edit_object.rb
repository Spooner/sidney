# encoding: utf-8

require_relative 'edit_selectable'
require_relative 'edit_sprite'

module Sidney
  class EditObject < EditSelectable
    include Log

    attr_reader :object

    protected
    def initialize
      super

      add_inputs(
        released_escape: :save,
        f1: ->{ push_game_state GameStates::Popup.new(text: t('edit_object.help', general: t('help'))) }
      )

      @state_bar = VerticalPacker.new(nil, padding: 0) do |packer|
        @save_button = Button.new(packer, icon: Image['save.png'],
                                          tip: t('edit_object.save_button.tip')) do |button|
          button.subscribe :clicked_left_mouse_button, method(:save)
        end

        @save_copy_button = Button.new(packer, icon: Image['copy_and_save.png'],
                                               tip: t('edit_object.save_copy_button.tip')) do |button|
          button.subscribe :clicked_left_mouse_button, method(:save_copy)
        end
      end
    end

    protected
    def save(*args)
      save_changes
      pop_game_state
    end

    protected
    def save_copy(*args)
      save # TODO: Actually make this do something different.
    end

    protected
    def edit
      @edit_sprite ||= EditSprite.new
      @edit_sprite.init(@selection[0], @object)
      push_game_state @edit_sprite

      nil
    end

    public
    def object=(object)
      @object = object
      @object.hide!

      @object
    end

    public
    def released_right_mouse_button
      return if @selection.dragging?
      x, y = $window.mouse_x, $window.mouse_y
      if grid.hit?(x, y)
        MenuPane.new(x: x, y: y) do |widget|
          widget.add_item(:edit, text: 'Edit', shortcut: 'Ctrl-E', enabled: @selection.size == 1)
          widget.add_item(:mirror, text: 'Mirror', shortcut: 'Ctrl-M', enabled: @selection.size == 1)
          widget.add_item(:flip, text: 'Flip vertically', shortcut: 'Ctrl-N', enabled: @selection.size == 1)
          widget.add_separator
          widget.add_item(:copy, text: 'Copy', shortcut: 'Ctrl-C', enabled: (not @selection.empty?))
          widget.add_item(:paste, text: 'Paste', shortcut: 'Ctrl-V', enabled: (@selection.empty? and not clipboard.empty?))
          widget.add_item(:delete, text: 'Delete', shortcut: 'Ctrl-X', enabled: (not @selection.empty?))

          widget.subscribe :selected do |widget, value|
            case value
              when :delete then delete
              when :copy   then copy
              when :paste  then paste(x, y) # Paste at position the menu was opened, not where the mouse was just clicked.
              when :edit   then edit
              when :flip   then @selection[0].flip!
              when :mirror then @selection[0].mirror!
            end
          end

          show_menu widget
        end
      end

      nil
    end

    protected
    def paste(x, y)
      return unless grid.hit?(x, y)

      # Work out the overall bounding box for the items on the clipboard.
      rects = clipboard.items.map { |o| o.rect }
      rect = rects.first.union_all(rects[1..-1])

      # Place all items from the clipboard down with the centre of the
      # bounding box at the mouse position.
      x, y = grid.screen_to_grid(x, y)
      offset_x, offset_y = (x - rect.centerx - @object.x).round, (y - rect.centery  - @object.y).round
      @selection.clear

      clipboard.items.each do |item|
        copy = item.dup
        copy.x += offset_x
        copy.y += offset_y
        copy.selected = true
        @object.state_object.cached_layers.push copy
        @selection.add copy
      end

      nil
    end

    protected
    def delete
      copy
      @selection.each {|o| object.state_object.cached_layers.delete(o) }
      @selection.clear

      nil
    end

    # @param [Integer] x
    # @param [Integer] y
    # @return [Boolean]
    protected
    def hit_object(x, y)
      x, y = grid.screen_to_grid(x, y)
      @object.hit_sprite(x, y)
    end

    # @return nil
    public
    def select_all
      # TODO: Only select the items that are unlocked?
      @object.state_object.cached_layers.each {|o| @selection.add o unless @selection.include? o }

      nil
    end

    public
    def save_changes
      # Save the current changes to the object being edited.
      @selection.clear
      @object.state_object.redraw

      @object.show!
      nil
    end

    public
    def grid_tip
      if sprite_layer = hit_object(cursor.x, cursor.y)
        sprite_layer.sprite.name
      else
        nil
      end
    end

    # @return nil
    public
    def draw
      grid.draw_with_respect_to do
        previous_game_state.scene.draw
        flush

        draw_checked_background
        flush

        @object.draw_layers
      end

      Element.font.draw("Object: '#{@object.state_object.name}' [#{@object.state_object.id}]", 10, $window.height - 25, ZOrder::GUI)

      super
    end
  end
end