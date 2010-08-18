require 'gui/combi_box'
require 'gui/clipboard'
require 'gui/selection'
require 'gui/history'
require 'states/gui_state'
require 'states/edit_object'
require 'states/show_menu'

module Sidney
class EditScene < GuiState
  include Log

  attr_reader :grid, :zoom_box

  protected
  def initialize
    super

    @grid = Grid.new(($window.height / 240).floor)

    zooms = {0.5 => "50%", 1 => "100%", 2 => "200%", 4 => "400%", 8 => "800%"}
    @zoom_box = CombiBox.new(@grid.rect.right + 12, 12, 20 * @grid.scale, 8 * @grid.scale, 1)
    zooms.each_pair do |key, value|
      @zoom_box.add(key, value)
    end
    @zoom_box.on_change do |widget, value|
      @grid.scale = value * @grid.base_scale
    end

    add_element(@zoom_box)

    @font = Font.new($window, nil, 14)

    self.input = {
      :g => lambda { @grid.toggle_overlay if $window.control_down? },
      :holding_left => lambda { @grid.left },
      :holding_right => lambda { @grid.right },
      :holding_up => lambda { @grid.up },
      :holding_down => lambda { @grid.down },
      :escape => lambda { @selection.reset_drag if @selection.dragging? },
      :delete => lambda { delete unless @selection.empty? },
      :e => lambda { edit_object if $window.control_down? and @selection.size == 1 },
      :x => lambda { delete if $window.control_down? and not @selection.empty? },
      :c => lambda { copy if $window.control_down? and not @selection.empty? },
      :v => lambda { paste($window.mouse_x, $window.mouse_y) if $window.control_down? and not @clipboard.empty? },
      :z => lambda {
         if $window.control_down?
           if $window.shift_down?
             @history.redo if @history.can_redo?
           else
             @history.undo if @history.can_undo?
           end
         end
      },
    }

    @clipboard = Clipboard.new
    @history = History.new
    @selection = Selection.new

    nil
  end

  public
  def mouse_wheel_up
    @zoom_box.index += 1
    nil
  end

  public
  def mouse_wheel_down
    @zoom_box.index -= 1
    nil
  end

  public
  def setup
    log.info { "Started editing scene"}
  end

  public
  def left_mouse_button
    x, y = $window.cursor.x, $window.cursor.y
    if @grid.hit?(x, y)
      select(x, y)

      x, y = @grid.screen_to_grid(x, y)
      @selection.begin_drag(x, y)
    end
    
    nil
  end

  protected
  def select(x, y)
    object = @grid.hit_object(x, y)

    unless @selection.include?(object) or $window.shift_down?
      @selection.clear
    end

    if object
      if @selection.include? object
        @selection.remove object if $window.shift_down?
      else
        @selection.add object
      end
    end

    nil
  end

  public
  def released_left_mouse_button
    x, y = $window.cursor.x, $window.cursor.y

    @zoom_box.click(x, y)

    if @selection.dragging?
      if @grid.hit?(x, y)
        @selection.end_drag
      else
        @selection.reset_drag
      end
    end

    nil
  end

  public
  def right_mouse_button
    return if @selection.dragging?
    x, y = $window.cursor.x, $window.cursor.y
    select(x, y) if @grid.hit?(x, y)

    nil
  end

  public
  def holding_right_mouse_button
  end

  public
  def released_right_mouse_button
    return if @selection.dragging?
    x, y = $window.mouse_x, $window.mouse_y
    if @grid.hit?(x, y)
      MenuPane.new(x, y, ZOrder::DIALOG) do |widget|
        widget.add(:edit, 'Edit', :shortcut => 'Ctrl-E', :enabled => @selection.size == 1)
        widget.add_separator
        widget.add(:copy, 'Copy', :shortcut => 'Ctrl-C', :enabled => (not @selection.empty?))
        widget.add(:paste, 'Paste', :shortcut => 'Ctrl-V', :enabled => (@selection.empty? and not @clipboard.empty?))
        widget.add(:delete, 'Delete', :shortcut => 'Ctrl-X', :enabled => (not @selection.empty?))

        widget.on_select do |widget, value|
          case value
            when :delete
              delete

            when :copy
              copy

            when :paste
              paste(x, y) # Paste at position the menu was opened, not where the mouse was just clicked.

            when :edit
              edit_object

          end
        end

        game_state_manager.push ShowMenu.new(widget)
      end
    end
    
    nil
  end

  protected
  def edit_object
    game_state_manager.push EditObject.new(@selection[0])
  end
  
  protected
  def delete
    copy
    @selection.each {|o| @grid.objects.delete(o) }
    @selection.clear

    nil
  end

  protected
  def paste(x, y)
    # Work out the overall bounding box for the items on the clipboard.
    rects = @clipboard.items.map { |o| o.rect }
    rect = rects.first.union_all(rects[1..-1])

    # Place all items from the clipboard down with the centre of the
    # bounding box at the mouse position.
    x, y = @grid.screen_to_grid(x, y)
    offset_x, offset_y = (x - rect.centerx).round, (y - rect.centery).round
    @selection.clear
    
    @clipboard.items.each do |item|
      copy = item.dup
      copy.x += offset_x
      copy.y += offset_y
      copy.selected = true
      @grid.objects.push copy
      @selection.add copy
    end

    nil
  end

  protected
  def copy
    @clipboard.copy(@selection)

    nil
  end

  public
  def update
    @grid.update
    x, y = $window.cursor.x, $window.cursor.y
    @selection.update_drag(*@grid.screen_to_grid(x, y)) if @selection.dragging?

    super
  end

  public
  def draw
    @grid.draw

    x, y = $window.cursor.x, $window.cursor.y
    if @grid.hit?(x, y)
      x, y = @grid.screen_to_grid(x, y)
      x, y = x.to_i, y.to_i
    else
      x, y = 'x', 'y'
    end

    @font.draw("(#{x}, #{y}) (#{@grid.objects.size} sprites and #{@grid.tiles.size} tiles) #{game_state_manager.current}", 0, 650, ZOrder::GUI)
    
    super
  end
end
end