#
# This class should be extended.  It is much like an abstract.
#

class Calculation_Element

  #
  # Initialize the object
  #
  def initialize value = nil

    # allow the instance to run pre_init functionality without overwriting
    # initialize method
    pre_init

    @can_be_cleared = true

    if (value)
      set_value value
    end

    # allow the instance to run post_init functionality without overwriting
    # initialize method
    post_init

  end

  #
  # Setup custom initializations for child instances
  #
  def post_init
  end
  def pre_init
  end

  #
  # Defines how this element will be converted to string.
  #
  def to_s
    raise CalculationError, 'Value of element is not set' if not @value
    @value.to_s
  end

  #
  # Directly read the value
  #
  def value
    @value
  end

  #
  # Handles a backspace request.  Must be extended
  #
  def apply_backspace
  end

  #
  # Used to switch the value from positive to negative.  Must be extended
  #
  def reverse_polarity
  end

  #
  # Used to directly set the value.  Must be extended.
  #
  def set_value new_value
    if validate_value new_value
      @value = new_value
    end
  end

  #
  # Validates that the given value is allowed for the current element
  #
  def validate_value value
    true
  end

  #
  # Returns whether the Calculation::clear method should apply to this element
  #
  def can_be_cleared?
    puts "***(#{@can_be_cleared})***"
    @can_be_cleared
  end

end