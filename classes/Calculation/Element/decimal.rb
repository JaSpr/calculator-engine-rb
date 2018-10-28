# -*- coding: utf-8 -*-
require_relative '../element'

class CalcDecimal < Calculation_Element

  #
  # Initialize, optionally setting value
  #
  def post_init
    @value = "."
  end

  #
  # Allow appending digits to the end of a decimal value (e.g. ".01")
  #
  def append_value value
    if value.is_a? Rational
      if value.to_i == value
        @value += value.to_i.to_s
      end
    elsif value.is_a? Fixnum or ((value.is_a? String or value.is_a? Symbol) and /^\d$/.match(value))
      @value += value.to_s
    else
      raise ArgumentError, "Value after the decimal point must be a number"
    end

  end

  #
  # Overwrites set_value method
  #
  def set_value value
    append_value value
  end

  #
  # Handles backspace requests.
  #
  def apply_backspace

    return drop_last_value if @value.length > 1
    false

  end

################################################################################
  private

  #
  # Drops the last character in the string
  #
  def drop_last_value
    if @value.length > 1
      @value[-1] = ""
      return true
    end
    false
  end

end