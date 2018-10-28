# -*- coding: utf-8 -*-
require_relative 'calculation.rb'

#
# Basic calculator object
#
class Calculator

  KEY_PLUS        = :+
  KEY_MINUS       = :-
  KEY_MULTIPLY    = :*
  KEY_DIVIDE      = :/
  KEY_EQUALS      = :"="
  KEY_DECIMAL     = :"."
  KEY_CLEAR       = :CE
  KEY_CLEAR_ALL   = :C
  KEY_SPACE       = :space
  KEY_PAREN_LEFT  = :"("
  KEY_PAREN_RIGHT = :")"
  KEY_BACK_SPACE  = :"←"
  KEY_PLUS_MINUS  = :"±"
  KEY_PI          = :"π"
  KEY_CARAT       = :^

  #
  # Initialize the object
  #
  def initialize
    @calculation = Calculation.new()
    @history     = []
  end

  #
  # Handles observation notifications for input key presses
  #
  def button_callback calculator_ui

    case calculator_ui.key_value

      when KEY_CLEAR
        # Clear (CE) removes the last operand or closed calculation,
        # if possible.
        @calculation.clear_last

      when KEY_CLEAR_ALL
        # Clear all removes the current calculation and restores to the last
        # historical result.  If clear is pressed while already showing the last
        # historical state, Clear all resets the calculator completely.

        @history = [] if @calculation.get_last_child.frozen?

        @calculation.clear

        if (@history.last)
          @last_calculation = @history.last.dup
          @last_calculation.set_not_historical
          result = @last_calculation.calculate_all

          @calculation.add_operand(result, true)
        end

      when (:"0"..:"9")
        # numeric keys add an operand (or add TO an operand))
        @calculation.add_operand(calculator_ui.key_value)

      when KEY_PI
        @calculation.add_operand(Math::PI, true)

      when KEY_EQUALS
        # EQUALS calculates the equation

        calculation_backup = @calculation.dup

        result = @calculation.calculate_all

        if (result)
          @history.push calculation_backup
          @calculation = Calculation.new
          @calculation.add_operand(result, freeze = true)
        end

      when KEY_PLUS, KEY_MINUS, KEY_MULTIPLY, KEY_DIVIDE, KEY_CARAT
        #adds a new operator
        @calculation.add_operator(calculator_ui.key_value)

      when KEY_DECIMAL
        # adds a new decimal value
        @calculation.add_decimal

      when KEY_SPACE
        # Prints debug code
        @calculation.puts_all

      when KEY_PAREN_LEFT
        # Open a new sub-calculation within the current calculation
        # or sub-calculation
        @calculation.add_sub_calculation

      when KEY_PAREN_RIGHT
        # close the current sub-calculation, if it exists
        @calculation.close_current

      when KEY_BACK_SPACE
        # Handles deletion of last character
        @calculation.apply_backspace

      when KEY_PLUS_MINUS
        # Handles the plus/minus
        @calculation.reverse_polarity

    end

    puts; print @calculation
  end

  #
  # Provides read access to the calculation
  #
  def calculation_string
    @calculation.to_s
  end

  #
  # Returns a string containing the last five calculations historically
  #
  def ticker_value

    history_string = String.new

    @history.each_with_index do |calculation, index|

      if ((@history.length - 5)..(@history.length)).include? index
        result_dup = calculation.dup
        result_dup.calculate_all

        history_string += calculation.to_s
        history_string += "\n" if calculation != @history.last
      end
    end

    history_string

  end

  ##############################################################################
  private

  #
  # Retrieves the current open (deepest level) calculation or sub-calculation
  #
  def current_calculation
    @calculation.get_current_calculation
  end

end