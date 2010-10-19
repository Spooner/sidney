require_relative 'gui_element'
require_relative 'menu_pane'
require_relative '../event'

module Sidney
class CombiBox < GuiElement
  include Event

  public
  attr_accessor :index

  public
  def index; @menu.index(@value) end
  def value; @value; end
  def text; @menu.find(@value).text; end
  
  public
  def value=(value)
    if @value != value
      @value = value
      publish :change, @value
    end
  end

  public
  def index=(index)
    if index.between?(0, @menu.size - 1)
      self.value = @menu[index].value
    end
  end

  def rect; @rect.dup; end

  protected
  def initialize(x, y, width, height, initial_value, options = {})
    super(x, y, width, height, ZOrder::GUI, options)

    @value = initial_value

    @border_color = 0xffffffff
    @background_color = 0xff666666
    
    @hover_index = 0

    @menu = MenuPane.new(rect.left, rect.bottom + 1, z + 0.01) do |widget|
      widget.subscribe :select do |widget, value|
        self.value = value
      end
    end

    yield self if block_given?
  end

  public
  def add(*args)
    @menu.add(*args)
  end

  public
  def update
    nil
  end

  public
  def draw
    $window.draw_box(rect.x, rect.y, rect.width, rect.height, z, @border_color, @background_color)
    font.draw(text, rect.x + PADDING_X, rect.y + ((rect.height - FONT_SIZE) / 2).floor, z)

    nil
  end

  public
  def menu_clicked(widget, value)
    self.value = value
  end

  public
  def click(x, y)
    hit = hit?(x, y)
    if hit
      $window.game_state_manager.push ShowMenu.new(@menu)
    end

    hit
  end
end
end