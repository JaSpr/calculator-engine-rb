# -*- coding: utf-8 -*-
require_relative '../element'

class Operand  < Calculation_Element


  #
  # Validates that the input is correct
  #
  def validate_value value
    raise ArgumentError, "Operand must be numeric: #{value}, #{value.class}" unless value.is_a? Numeric
    true
  end

  #
  # Append to a value (appending value 2 to a value of 1 makes 12 (not 3))
  #
  def append_value  value
    if value.is_a? Numeric or (value.respond_to?(:to_i) and value.to_i)
      if @value >=0
        @value = ((@value * 10) + value.to_i)
      else
        @value = ((@value * 10) - value.to_i)
      end
    else
      raise ArgumentError, "Operand must be numeric: #{value}, #{value.class}"
    end

  end

  #
  # When printed to screen, return the string value of the value.
  #
  def to_s
    if (@value)
      if (@value.to_i == @value)
        @value.to_i.to_s
      else

        float_digits = get_minimum_float

        rounded_value = "%.#{float_digits}f" % [@value.to_f]

        if Rational(rounded_value) != @value
          rounded_value += "…"
        end

        rounded_value
      end
    else
      raise CalculationError, 'Value of operand is not set'
    end
  end

  #
  # Handles a backspace request
  #
  def apply_backspace
    if not frozen?
      # handle backspacing negatives, too
      if (@value.to_i.to_s.length > 1 and @value >= 0) or (@value.to_i.to_s.length > 2 and @value < 0)
        drop_last_value
        return true
      end
    end

    false
  end

  #
  # Reverse polarity
  #
  def reverse_polarity
    @value = @value * (0-1)
    true
  end

  ##############################################################################
  private

  #
  # Drops the last digit of an integer (does not work on pre-calculated values)
  #
  def drop_last_value
    if @value.to_i.to_s.length > 1
      if (@value > 0)
        @value = (@value.to_i / 10).to_r
      else
        # Negative truncations need to be rounded UP
        @value = (@value.to_i / 10 + 1).to_r
      end
    else
      @value = 0
    end
  end

  #
  # Returns the minimum number of digits after the decimal to display an equal
  # Number (e.g. 2.500000 can be displayed as 2.5 (returns 1))
  #
  def get_minimum_float
    maximum_float = 15 - @value.to_i.to_s.length

    return 0 if maximum_float < 1

    (0..maximum_float).each do |num_digits|
      if @value.to_f.round(num_digits) == @value
        return num_digits
      end
    end

    maximum_float
  end


end