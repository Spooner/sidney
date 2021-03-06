# encoding: utf-8

begin
  begin
    require 'minigems'
  rescue LoadError => ex
    require 'rubygems'
  end
rescue LoadError => ex
  STDERR.puts ex
end

# Allow gems to find the bin directory for binary libraries.
ENV['PATH'] = "#{File.join(ROOT_PATH, 'bin')};#{ENV['PATH']}"

#require 'profile'

# Gems

begin; gem 'activerecord'; rescue Exception => ex; end
require 'active_record'
begin; gem 'i18n'; rescue Exception => ex; end
require 'i18n'
begin; gem 'chingu'; rescue Exception => ex; end
require 'chingu'
require 'devil'
require 'devil/gosu'

if defined? Ocra
  require 'fidgit' # Ocra MUST compile with the gem.
else
  begin
    # For development, run from my local version.
    require_relative File.join(ROOT_PATH, '/../fidgit/lib/fidgit')
  rescue Exception => ex
    require 'fidgit'
  end
end

Fidgit.default_font_name = File.join(ROOT_PATH, 'media', 'fonts', 'SFPixelate.ttf')

I18n.load_path << Dir[File.join(ROOT_PATH, 'config', 'locales', '*.yml')]

include Gosu
include Chingu
include Fidgit

module Sidney
# Z-order of all elements of the game.
module ZOrder
  SCENE, SCENE_FILTER, GUI, BUBBLE, DIALOG, FPS = (0..1000).to_a
  OUTLINE = GUI
end
end

require_relative 'log'
require_relative 'database'
require_relative 'fps_display'
require_relative 'grid'
require_relative 'states/pick_scene'
require_relative 'resources'

module Sidney
# Main game window.
class Game < Window
  include Log

  # Any taller and Gosu will scale the whole window to fit.
  MAX_HEIGHT = Gosu::screen_width * 0.8
  # Any wider and Gosu will scale the whole window to fit.
  MAX_WIDTH = Gosu::screen_width * 0.9

  CLEAR_COLOR = Color.rgb(0, 0, 0)
  TRANSPARENT_COLOR = Color.rgba(0, 0, 0, 0)
  
  protected
  def initialize(full_screen)
    #width, height = 400, 300
    width, height = 800, 600
    #width, height = 1200, 900
    #width, height = 800 * 16 / 10, 800

    #width, height = 800, 600
    #width, height = Gosu::screen_width, Gosu::screen_height

    super(width, height, full_screen)
    log.info { "Opened window" }
  end

  def setup
    media_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'media'))
    Image.autoload_dirs << File.join(media_dir, 'images')
    Sample.autoload_dirs << File.join(media_dir, 'sounds')

    retrofy

    self.caption = t 'window_title'

    on_input(:f) { @fps.toggle if holding_control? }

    @fps = FPSDisplay.new(0, 0)

    push_game_state(PickScene)
   
    nil
  end

  protected
  def draw
    @fps.draw

    super
  end

  public
  def t(*args); I18n.t(*args); end

  # Holding either shift key?
  public
  def holding_shift?
    holding_any? :left_shift, :right_shift
  end

  # Holding either control key?
  public
  def holding_control?
    holding_any? :left_control, :right_control
  end

  # Holding either alt key?
  public
  def holding_alt?
    holding_any? :left_alt, :right_alt
  end

  # Close the window.
  public
  def close
    log.info { "Closed window" }
    super
  end

  # Exited the applications, for example by pressing the window-X.
  public
  def exited
    log.info { "Exited application" }
  end

  # Run the application.
  public
  def self.run
    return if defined? Ocra

    full_screen = case ARGV
                    when []
                      false
                    when ["--full-screen"], ["-f"]
                      true
                    else
                      return "Usage:\n  #{File.basename($0)} [--full-screen]"
                      nil
                  end

    new(full_screen).show
  end
end
end

at_exit { $window.exited if $window and $window.is_a? Sidney::Game }

