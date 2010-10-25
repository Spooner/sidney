# encoding: utf-8

module Sidney
module Gui
  class TextArea < Element
    FOCUS_BORDER_COLOR = Color.rgb(0, 255, 255)
    BLUR_BORDER_COLOR = Color.rgb(255, 255, 255)
    CARET_COLOR = Color.rgb(255, 0, 0)
    SELECTION_COLOR = Color.rgb(100, 100, 100)
    CARET_PERIOD = 500 # ms

    # @return [Number]
    attr_reader :min_height
    # @return [Number]
    attr_reader :max_height

    # @return [Number]
    attr_reader :line_spacing

    # @param [Boolean] value
    # @return [Boolean]
    attr_writer :editable

    public
    # Is the area editable?
    def editable?
      @editable
    end

    public
    # Text within the element.
    # @return [String]
    def text
      @text_input.text
    end

    public
    # Returns the range of the selection.
    #
    # @return [Range]
    def selection_range
      from = [@text_input.selection_start, caret_position].min
      to = [@text_input.selection_start, caret_position].max

      (from...to)
    end

    public
    # Returns the text within the selection.
    #
    # @return [String]
    def selection_text
      text[selection_range]
    end

    public
    # Position of the caret.
    #
    # @return [Integer] Number in range 0..text.length
    def caret_position
      @text_input.caret_pos
    end

    public
    # Position of the caret.
    #
    # @param [Integer] pos Position of caret in the text.
    # @return [Integer] New position of caret.
    def caret_position=(position)
      raise ArgumentError, "Caret position must be in the range 0 to the length of the text (inclusive)" unless position.between?(0, text.length)
      @text_input.caret_pos = position

      position
    end

    public
    # Sets caret to the end of the text.
    #
    # @param [String] text
    # @return [String] Current string (may be the old one if passed on was too long).
    def text=(text)
      @text_input.text = text
      recalc # This may roll back the text if it is too long.
      self.text
    end

    protected
    # @option options [String] :text ("")
    # @option options [Boolean] :editable (false)
    # @option options [Integer] :height Sets both min and max height at once.
    # @option options [Integer] :min_height
    # @option options [Integer] :max_height (Infinite)
    # @option options [Number] :line_spacing (0)
    def initialize(parent, options = {}, &block)
      options = {
        editable: false,
        text: '',
        max_height: Float::INFINITY,
        line_spacing: 0
      }.merge! options

      @editable = options[:editable]
      @line_spacing = options[:line_spacing]
      @lines = [''] # List of lines of wrapped text.
      @text_positions = [[0, 0, 0]] # [x, y, width] of each character.
      @text_input = TextInput.new
      @old_text = ''
      @old_caret_position = 0
      @old_selection_start = 0

      @text_input.text = options[:text]

      super(parent, options)

      min_height = (padding_y * 2) + font_size
      if options[:height]
        @max_height = @min_height = [options[:height], min_height].max
      else
        @max_height = [options[:max_height], min_height].max
        @min_height = options[:min_height] ? [options[:min_height], min_height].max : min_height
      end
      rect.height = [(padding_y * 2) + font_size, @min_height].max
    end

    public
    # @return [nil]
    def clicked_left_mouse_button(sender, x, y)
      focus unless focused?

      # Move caret to position the user clicks on.
      mouse_x, mouse_y = $window.cursor.x - x - padding_x, $window.cursor.y - y - padding_y
      @text_positions.each.with_index do |data, index|
        x, y, width = data
        if mouse_x.between?(x, x + width) and mouse_y.between?(y, y + font_size)
          self.caret_position = @text_input.selection_start = index
          break
        end
      end

      nil
    end

    public
    # Does the element have the focus?
    def focused?; @focused; end

    public
    # @return [nil]
    def focus
      @focused = true
      $window.current_game_state.focus = self
      $window.text_input = @text_input

      nil
    end

    public
    # @return [nil]
    def blur
      if focused?
        $window.current_game_state.focus = nil
        $window.text_input = nil
      end

      @focused = false

      nil
    end

    # y position of the
    protected
    def y_at_line(lines_number)
      lines_number * (font_size + line_spacing)
    end

    protected
    # Helper for #recalc
    # @return [Integer]
    def position_letters_in_word(word, line_width)
      word.each_char do |c|
        char_width = font.text_width(c)
        line_width += char_width
        @text_positions.push [line_width, y_at_line(@lines.size), char_width]
      end

      line_width
     end

    public
    # @return [nil]
    def layout
      # Don't need to re-layout if the text hasn't changed.
      return if @old_text == text

      # Save these in case we are too long.
      old_lines = @lines
      old_text_positions = @text_positions

      @lines = []
      @text_positions = [[0, 0, 0]] # Position 0 is before the first character.

      space_width = font.text_width ' '
      max_width = width - padding_x * 2 - space_width

      line = ''
      line_width = 0
      word = ''
      word_width = 0

      text.each_char do |char|
        char_width = font.text_width(char)

        overall_width = line_width + (line_width == 0 ? 0 : space_width) + word_width + char_width
        if overall_width > max_width and not (char == ' ' and not word.empty?)
          if line.empty?
            # The current word is longer than the whole word, so split it.
            # Go back and set all the character positions we have.
            position_letters_in_word(word, line_width)
            line_width = 0

            # Push as much of the current word as possible as a complete line.
            @lines.push word + (char == ' ' ? '' : '-')

            word = ''
            word_width = 0
          else
            # Adding the current word would be too wide, so add the current line and start a new one.
            @lines.push line
            line = ''
            line_width = 0
          end
        end

        case char
          when "\n"
            # A new-line ends the word and puts it on the line.
            line += word
            line_width = position_letters_in_word(word, line_width)
            @text_positions.push [line_width, y_at_line(@lines.size), 0]
            @lines.push line
            word = ''
            word_width = 0
            line = ''
            line_width = 0

          when ' '
            # A space ends a word and puts it on the line.
            line += word + char
            line_width = position_letters_in_word(word, line_width)
            line_width += space_width
            @text_positions.push [line_width, y_at_line(@lines.size), space_width]

            word = ''
            word_width = 0

          else
            # If there was a previous line and we start a new line, put the caret pos on the current line.
            if line.empty?
              @text_positions.last[0..1] = [0, y_at_line(@lines.size)]
            end

            # Start building up a new word.
            word += char
            word_width += char_width
        end
      end

      # Add any remaining word on the last line.
      unless word.empty?
        position_letters_in_word(word, line_width)
        line += word
      end

      @lines.push line if @lines.empty? or not line.empty?

      # Roll back if the height is too long.
      new_height = (padding_y * 2) + y_at_line(@lines.size)
      if new_height <= max_height
        @old_text = text
        rect.height = [new_height, @min_height].max
        @old_caret_position = caret_position
        @old_selection_start = @text_input.selection_start
      else
        # Roll back!
        @lines = old_lines
        @text_positions = old_text_positions
        @text_input.text = @old_text
        self.caret_position = @old_caret_position
        @text_input.selection_start = @old_selection_start
      end

      nil
    end

    public
    # Draw the text area.
    #
    # @return [nil]
    def draw
      # Always roll back changes made by the user unless the text is editable.
      if not editable? and text != @old_text
        @text_input.text = @old_text
        @text_input.selection_start = @old_selection_start
        self.caret_position = @old_caret_position
      else
        @old_caret_position = caret_position
        @old_selection_start = @text_input.selection_start
      end

      recalc if focused?

      # Draw the border.
      $window.draw_box x, y, width, height, z, @focused ? FOCUS_BORDER_COLOR : BLUR_BORDER_COLOR, BACKGROUND_COLOR

      caret_x, caret_y = @text_positions[caret_position]

      # Draw the selection.
      selection_range.each do |i|
        char_x, char_y = @text_positions[i]
        left, top = x + padding_x + char_x, y + padding_y + char_y
        $window.draw_box left, top, font.text_width(text[i]), font_size,
                       z, nil, SELECTION_COLOR
      end

      # Draw text.
      @lines.each_with_index do |line, index|
        font.draw(line, x + padding_x, y + padding_y + y_at_line(index), z)
      end

      # Draw the caret.
      if focused? and ((milliseconds / CARET_PERIOD) % 2 == 0)
        left, top = x + padding_x + caret_x, y + padding_y + caret_y
        $window.draw_line left, top, CARET_COLOR, left, top + font_size, CARET_COLOR, z
      end
    end
  end
end
end