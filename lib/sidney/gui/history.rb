module Sidney
module Gui
# Manages a history of actions, along with doing, undoing and redoing those actions.
class History
  # Maximum number of actions in the History before Actions are deleted.
  DEFAULT_MAX_SIZE = 250

  # An action in the History. Inherit actions from this in order to add them to a History.
  class Action
    # Perform the action.
    public
    def do; raise NotImplementedError, "#{self.class} does not have a do method defined"; end

    # Reverse the action.
    public
    def undo; raise NotImplementedError, "#{self.class} does not have an undo method defined"; end
  end

  # Is there an action that can be undone?
  public
  def can_undo?; @last_done >= 0; end

  # Is there an action that has been undone that can now be redone?
  public
  def can_redo?; @last_done < (@actions.size - 1); end

  protected
  def initialize(max_size = DEFAULT_MAX_SIZE)
    @max_size = max_size
    @actions = []
    @last_done = -1 # Last command that was performed.
  end

  # Perform a History::Action, adding it to the history.
  # If there are currently any actions that have been undone, they will be permanently lost and cannot be redone.
  #
  # === Parameters
  # +action+:: Action to be performed [Action]
  public
  def do(action)
    raise ArgumentError, "Parameter, 'action', expected to be a #{Action}, but received: #{action}" unless action.is_a? Action

    # Remove all undone actions when a new one is performed.
    @actions = @actions[0..@last_done] if can_redo?

    # If history is too big, remove the oldest action.
    if @actions.size >= @max_size
      @actions.shift
    end
    
    @last_done = @actions.size
    @actions << action
    action.do

    nil
  end

  # Perform a History::Action, replacing the last action that was performed.
  #
  # === Parameters
  # +action+:: Action to be performed [History::Action]
  def replace_last(action)
    raise ArgumentError, "Parameter, 'action', expected to be a #{Action}, but received: #{action}" unless action.is_a? Action

    @actions[@last_done].undo
    @actions[@last_done] = action
    action.do

    nil
  end

  # Undo the last action that was performed.
  public
  def undo
    raise "Can't undo unless there are commands in past" unless can_undo?

    @actions[@last_done].undo
    @last_done -= 1

    nil
  end

  # Redo the last action that was undone.
  public
  def redo
    raise "Can't redo if there are no commands in the future" unless can_redo?

    @last_done += 1
    @actions[@last_done].do

    nil
  end
end
end
end