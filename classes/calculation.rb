# -*- coding: utf-8 -*-
require_relative 'Calculation/Element/operand'
require_relative 'Calculation/Element/operator'
require_relative 'Calculation/Element/decimal'

#
# Single calculation object
#
class Calculation

  #
  # Initialize the object
  #
  def initialize

    @order_of_operations = {
        0 => [Calculator::KEY_CARAT],
        1 => [Calculator::KEY_MULTIPLY, Calculator::KEY_DIVIDE],
        2 => [Calculator::KEY_PLUS, Calculator::KEY_MINUS],
    }

    @stack    = []
    @value    = nil
    @closed   = nil
    @negative = false
    @is_error = false
    @error    = "";

  end

  #
  # Add an operator
  #
  def add_operator(key_value)

    raise CalculationError, "Cannot add values to a closed calculation" if is_closed?

    return get_last_child.add_operator(key_value) if has_open_sub?

    if (get_last_child)
      if (get_last_child.is_a? Operator)
        drop_last_child

        puts unless is_historical?
        print self.to_s unless is_historical?

      end
      add_child Operator.new(key_value)
    end
  end

  #
  # Add an operand
  #
  def add_operand(key_value, frozen = false)

    raise CalculationError "Cannot add values to a closed calculation" if is_closed?

    return get_last_child.add_operand(key_value) if has_open_sub?

    operand = Operand.new(Rational(key_value.to_s))
    operand.freeze if frozen

    if (get_last_child)
      if get_last_child.frozen? or get_last_child.is_a? Calculation

        drop_last_child
        add_child operand
        puts unless is_historical?

      elsif [Operand, CalcDecimal].include? get_last_child.class

        get_last_child.append_value(operand.value)

      elsif get_last_child.is_a? Operator

        add_child operand

      end
    else

      add_child operand

    end
  end


  #
  # Add a decimal value
  #
  def add_decimal

    raise CalculationError "Cannot add values to a closed calculation" if is_closed?

    return get_last_child.add_decimal if has_open_sub?

    if not get_last_child or not get_last_child.is_a? CalcDecimal

      #add a preceding zero when needed
      if (not get_last_child or get_last_child.frozen? or [Operator, Calculation].include? get_last_child.class)
        zero_operand = Operand.new 0
        add_operand(zero_operand)
      end

      add_child CalcDecimal.new

    end
  end

  #
  # Adds a new sub-calculation to the latest open calculation
  #
  def add_sub_calculation

    raise CalculationError "Cannot add values to a closed calculation" if is_closed?

    return get_last_child.add_sub_calculation if has_open_sub?

    if (get_last_child and [Operand, Calculation, CalcDecimal].include? get_last_child.class)

      drop_last_child
      drop_last_child if (get_last_child and get_last_child.is_a? Operand)  #additional drop

      puts unless is_historical?
      print self.to_s unless is_historical?

    end

    calculation = Calculation.new
    add_child calculation

    calculation
  end

  #
  # calculate the equation and return the value
  #
  def calculate_all

    if (@stack.length == 0)
      return Rational(0)
    end

    if get_current_calculation.get_last_child
      if [Operand, CalcDecimal, Calculation].include? get_current_calculation.get_last_child.class
        if [Operand, Calculation].include? get_current_calculation.get_first_child.class

          while (@stack.length > 1 or @stack.first.is_a? Calculation) and not is_error?
            parse_equation
          end

          if (@stack.length == 1)
            print " = "  unless is_historical?
            print self  unless is_historical?
            return (@stack[0].value * (0-1)) if is_negative?
            return @stack[0].value
          end

        end

      end
    end

  end

  #
  # If object is converted to a string, return a string of all operands and
  # operators in the order that they were entered.
  #
  def to_s
    if @is_error and not @error.empty?
      return @error
    end

    return_string = String.new
    @stack.each do |op|
      if (op.is_a? Calculation)
        return_string += "-" if op.is_negative?
        return_string += "(#{op.to_s}"
        return_string += ")" if (op.is_closed?)
      else
        return_string += "#{op}"
      end
    end
    if return_string == "" and is_closed?
      return_string += "0"
    end
    return_string
  end

  #
  # Debug inspector for calculations
  #
  def puts_all depth = 0
    indent = 2

    puts if depth == 0

    (indent * depth).times do print " " end
    puts "((*************************==> "

    @stack.each_with_index do |op, index|
      if (op.is_a? Calculation)
        op.puts_all(depth + 1)
      else
        (indent * depth).times do print " " end
        puts "{#{index}} :: #{op.class} :: #{op.value} :: #{op.value.class}"
      end
    end
    (indent * depth).times do print " " end
    puts "<== *************************))"

  end

  def close_current
    if get_current_calculation != self
      get_current_calculation.close
    end
  end

  def apply_backspace
    if is_closed?
      open
      return true
    elsif not_empty?
      drop_last_child unless get_last_child.apply_backspace
      return true
    end
    false
  end

  #
  # reset the calc
  #
  def clear
    initialize
  end

  #
  # Clears the last element of the last open calculation, if possible
  #
  def clear_last

    return get_last_child.clear_last if has_open_sub?

    while get_last_child and get_last_child.can_be_cleared?
      drop_last_child
    end

  end

  #
  # Handles a request to reverse the polarity of the active element
  #
  def reverse_polarity
    if is_closed?
      @negative = !@negative
    elsif not_empty?
      if get_last_child.is_a? CalcDecimal
        if @stack[-2].is_a? Operand
          if @stack[-3].is_a? Operator and @stack[-3].reverse_polarity
            return
          else
            @stack[-2].reverse_polarity
          end
        end
      else
        if get_last_child.is_a? Operand
          if get_last_child.frozen?
            value = get_last_child.value
            drop_last_child
            add_operand(value)
            get_last_child.reverse_polarity
            get_last_child.freeze
          elsif @stack[-2].is_a? Operator and @stack[-2].reverse_polarity
            return
          else
            get_last_child.reverse_polarity
          end
        elsif get_last_child.is_a? Calculation
          if get_last_child.is_closed?
            if @stack[-2].is_a? Operator and @stack[-2].reverse_polarity
              return
            end
          else
            get_last_child.reverse_polarity
          end
        end

      end
    end
  end

  #
  # Returns the open sub-calculation, if there is one, otherwise, returns self
  # as the active calculation
  #
  def get_current_calculation
    if has_open_sub?
      get_last_child.get_current_calculation
    else
      self
    end
  end

  #
  # Returns the last operator or operand entered (if any)
  #
  def get_last_child
    @stack.last
  end

  #
  # Returns the first operator or operand entered (if any)
  #
  def get_first_child
    @stack.first
  end

  def dup
    history_calculation = Calculation.new
    history_calculation.is_historical = true
    history_calculation.set_as_negative if @negative

    @stack.each do |entry|
      if entry.class == Calculation

        new_entry = entry.dup
        new_entry.close if new_entry.is_open?
        new_entry.is_historical = true

        history_calculation.stack.push new_entry

      else
        history_calculation.stack.push entry
      end

    end


    history_calculation
  end

  def set_not_historical
    is_historical = false
  end


  ##############################################################################
  private

  def is_empty?
    @stack.length == 0
  end

  def not_empty?
    @stack.length > 0
  end

  def has_open_sub?
     (get_last_child.is_a? Calculation and get_last_child.is_open?)
  end

  #
  # Add a new entry in @stack
  #
  def add_child child
    @stack.push child
  end

  #
  # Drop the last entry in @stack
  #
  def drop_last_child
    @stack.pop
  end

  #
  # Opens the current calculation
  #
  def open
    @closed = false
  end

  #
  # Parses the equation and returns on each successful sub-calculation
  #
  def parse_equation

    # Merge all CalcDecimals with their preceding Operands (0 + ".01" = 0.01)
    @stack.each_with_index do |op,index|
      if (op.is_a? CalcDecimal)
        begin
          # merge the two values
          replacement_value  = (@stack[index - 1].value) + Rational("0" + op.value + "0")
          @stack[(index-1), 2] = Operand.new(replacement_value)
        end
      elsif (op.is_a? Calculation)
        replacement_value = op.calculate_all
        if op.is_error?
          @is_error = true
          @error    = op.error
        else
          @stack[index] = Operand.new(replacement_value)
        end
      end
    end

    #start computing the mathematical operations
    @order_of_operations.each_value do |operators|
      @stack.each_with_index do |op,index|
        if (op.is_a? Operator and operators.include? op.value)
          begin
            replacement_value = calculate(@stack[(index - 1)], op, @stack[index + 1])
          rescue
            puts "ERROR CALCULATING: #{@stack[(index - 1)]}, #{op}, #{@stack[index + 1]}"
            puts "#{@stack} at index #{index}"
            raise
          end
          @stack[(index - 1),3] = Operand.new(replacement_value)
          return
        end
      end
    end

  end

  #
  # calculate a single object
  #
  def calculate operand_one, operator, operand_two

    value = nil

    # for all calculations, briefly convert to a Rational
    op_1 = Rational(operand_one.value)
    op_2 = Rational(operand_two.value)

    case operator.value
      when Calculator::KEY_PLUS
        value = op_1 + op_2
      when Calculator::KEY_MINUS
        value = op_1 - op_2
      when Calculator::KEY_MULTIPLY
        value = op_1 * op_2
      when Calculator::KEY_DIVIDE
        begin
          value = op_1 / op_2
        rescue ZeroDivisionError
          @is_error = true
          @error = "Cannot divide by zero."
        end
      when Calculator::KEY_CARAT
        if op_1 < 0 and op_2 < 1 and op_2 > 0 and ((1/op_2) % 2 == 0)
          @is_error = true
          @error    = "Cannot calculate imaginary numbers"
        else
          require 'bigdecimal'
          value = Rational(op_1.to_f ** op_2.to_f)
        end

    end

    value

  end

  ##############################################################################
  protected

  def can_be_cleared?
    if is_closed?
      true
    else
      false
    end
  end

  def is_closed?
    @closed
  end

  def is_open?
    not @closed
  end

  def is_negative?
    @negative
  end

  def set_as_negative
    @negative = true
  end

  #
  # Accessors
  #
  def value
    @value
  end

  def close
    if get_last_child.is_a? Operator
      drop_last_child
    end
    @closed = true
  end

  def stack= value
    @stack = value
  end

  def stack
    @stack
  end

  def is_historical= value
    @historical = value
  end

  def is_historical?
    not (not @historical)
  end

  def is_error?
    @is_error
  end

  def error
    @error
  end


end


class CalculationError < StandardError
end