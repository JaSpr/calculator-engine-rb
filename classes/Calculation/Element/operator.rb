# -*- coding: utf-8 -*-
require_relative '../element'

class Operator < Calculation_Element

  #
  # Initialize
  #
  def post_init
    @can_be_cleared = false
  end

  #
  # Handles a request to reverse polarity
  #
  def reverse_polarity
    case @value
      when :+
        @value = :-
        return true
      when :-
        @value = :+
        return true
    end
    false
  end

  #
  # Decides whether a value for assignment is valid.
  #
  def validate_value value
    allowed_chars = [:+, :-, :*, :/, :^]
    raise ArgumentError, "Operator must be +, -, *, /" unless allowed_chars.include? value.to_sym
    true
  end

end