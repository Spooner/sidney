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
        f1: ->{ push_game_state Chingu::GameStates::Popup.new(text: t('edit_object.help', general: t('help'))) }
      )

      add_element previous_game_state.grid
      add_element previous_game_state.zoom_box

      @save_button = Sidney::Button.new(662, 120, t('edit_object.save_button.text'),
                                        tip: t('edit_object.save_button.tip')) do |button|
        button.subscribe :click, method(:save)
        add_element(button)
      end

      @save_copy_button = Sidney::Button.new(662, 150, t('edit_object.save_copy_button.text'),
                                             tip: t('edit_object.save_copy_button.tip')) do |button|
        button.subscribe :click, method(:save_copy)
        add_element(button)
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
        MenuPane.new(x, y) do |widget|
          widget.add(:edit, 'Edit', shortcut: 'Ctrl-E', enabled: @selection.size == 1)
          widget.add(:mirror, 'Mirror', shortcut: 'Ctrl-M', enabled: @selection.size == 1)
          widget.add(:flip, 'Flip vertically', shortcut: 'Ctrl-N', enabled: @selection.size == 1)
          widget.add_separator
          widget.add(:copy, 'Copy', shortcut: 'Ctrl-C', enabled: (not @selection.empty?))
          widget.add(:paste, 'Paste', shortcut: 'Ctrl-V', enabled: (@selection.empty? and not clipboard.empty?))
          widget.add(:delete, 'Delete', shortcut: 'Ctrl-X', enabled: (not @selection.empty?))

          widget.subscribe :select do |widget, value|
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

    public
    def setup
      log.info { "Started editing object" }
      add_element(zoom_box) unless @elements.include? zoom_box
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
      previous_game_state.draw
      $window.flush # Ensure that all assets drawn by the previous mode are rendered.

      grid.draw_with_respect_to do
        @object.draw_layers
      end

      super
    end
  end
end