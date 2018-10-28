# -*- coding: utf-8 -*-

require 'gtk2'
require 'observer'
require_relative 'calculator.rb'

#
# Basic calculator object
#
class Calculator_Window

  include Observable
  attr_reader :key_value, :screen

  #
  # Initialize the object
  #
  def initialize

    @calculator_api = Calculator.new()

    add_observer @calculator_api, :button_callback

    @buttons   = {}
    @structure = get_structure

    @accelerator_group = Gtk::AccelGroup.new
    @accelerator_mods  = Gdk::Window::ModifierType.new
    @accelerator_flags = Gtk::AccelFlags.new

    init_window
    @screen  = @structure[:screen][:element]
    @history = @structure[:history][:element]

    @history_buffer = Gtk::TextBuffer.new
    @history.set_buffer @history_buffer

    @display_updater = init_display_updater 30

    @window.show_all

    @history.hide

    Gtk.main

  end


  #
  # Create the screen object and set its defaults
  #
  def init_screen screen

    screen.set_editable  false
    screen.set_xalign    1
    screen.set_can_focus false

  end


  #
  # Create the screen object and set its defaults
  #
  def init_history history

    history.set_editable           false
    history.set_can_focus          false
    history.set_justification      1

  end

  #
  # Create a window object and set its defaults
  #
  def init_window

    @window = Gtk::Window.new

    @window.border_width = 10
    @window.resizable    = false

    @window.signal_connect("delete_event") do
      puts; puts; puts "delete event occurred"
      false
    end

    @window.signal_connect("key_press_event") do |w, e|

      key = Gdk::Keyval.to_name(e.keyval)

      masks = get_key_masks e

      case
        when (masks[:ctrl] and not masks[:shift])
          case key
            when "space"
              handle_input Calculator::KEY_SPACE
            when "p", "P"
              handle_input Calculator::KEY_PI
          end

      end


    end

    @window.add_accel_group(@accelerator_group)

    @window.signal_connect("destroy") do
      puts "destroy event occurred"
      Gtk.main_quit
    end

    generate_structure @structure, @window

    init_screen  @structure[:screen][:element]
    init_history @structure[:history][:element]

  end

  #
  # Creates a new thread to update the calculator screen and history ticker
  # using the given fps refresh rate.
  #
  def init_display_updater(fps = 20)

    Raise ArgumentError, "Argument must be numeric" if not fps.is_a? Numeric

    Thread.new do
      while true

        # Update current calculation display
        @screen.text = @calculator_api.calculation_string
        @screen.text = "0" if @screen.text == ""

        #update historical display
        @history_buffer.set_text @calculator_api.ticker_value
        @history.show if @history_buffer.get_text != ""
        @history.hide if @history_buffer.get_text == ""

        # pause 1/20th of a second
        sleep Rational(1) / Rational(fps) # 20 FPS

      end
    end
  end


  #
  # Create a single button, and initialize it and its events
  #
  def create_button value

    button = Gtk::Button.new(value)

    # handle keyboard input, which uses "active" event on button
    button.signal_connect("activate") do |widget|
      handle_input widget.label
    end

    # handle mouse-click event, which uses "pressed" event
    button.signal_connect("pressed") do |widget|
      handle_input widget.label
    end

    button.set_can_focus false

    button

  end

  #
  # Generate multiple buttons via button hash options
  #
  def create_buttons buttons, parent = nil

    buttons.each do |label, options|
      button = create_button(label)

      modifiers = options[:modifiers] || @accelerator_mods
      parent    = options[:parent]    || parent

      options[:keys].each do |key|

        key = Gdk::Keyval.from_name(key) if key.is_a? String

        button.add_accelerator(
            "activate",                   # event to call
            @accelerator_group,           # accelerator group
            key,                       # Value of the key that will call this event
            modifiers,                    # any key modifiers (shift, ctrl, etc)
            @accelerator_flags            # accelerator flags
        )
      end

      # if the parent exists, add this button to the parent
      parent.pack_start(button, true, true) unless !parent

      @buttons[label] = button
    end

  end

  #
  # Notifies the calculator that a user has pressed an input button
  #
  def handle_input key_value

    @key_value = key_value.to_sym
    changed
    notify_observers self

  end

  #
  # Iterates through a given hash to generate the defined window structure
  #
  def generate_structure hash, parent

    if hash.is_a? Hash
      hash.each do |key, value|
        if key == :element
            if parent.class == @window.class
              parent.add(value)
            else
              parent.pack_start(value, true, true)
          end
        elsif key == :buttons
          @buttons.merge! create_buttons value, hash[:element]
        elsif value.is_a? Array
          value.each do |single_value|
             generate_structure single_value, hash[:element]
          end
        elsif value.is_a? Hash
          generate_structure value, hash[:element]
        end
      end
    end

  end

  def get_structure
    {
        element: Gtk::VBox.new(false, 5),
        history: {element: Gtk::TextView.new},
        screen:  {element: Gtk::Entry.new},
        button_holder: {
            element: Gtk::HBox.new(false, 0),
            integers: {
                element: Gtk::VBox.new(true, 0),
                rows: [
                    {
                        element: Gtk::HBox.new(true, 1),
                        buttons: {
                            Calculator::KEY_BACK_SPACE => {keys: [Gdk::Keyval::GDK_BackSpace]},
                            Calculator::KEY_CLEAR      => {keys: [Gdk::Keyval::GDK_Delete]},
                            Calculator::KEY_CLEAR_ALL  => {keys: [Gdk::Keyval::GDK_Escape]},
                        }
                    },
                    {
                        element: Gtk::HBox.new(true, 1),
                        buttons: {
                            :"7" => {keys: [Gdk::Keyval::GDK_7, Gdk::Keyval::GDK_KP_7]},
                            :"8" => {keys: [Gdk::Keyval::GDK_8, Gdk::Keyval::GDK_KP_8]},
                            :"9" => {keys: [Gdk::Keyval::GDK_9, Gdk::Keyval::GDK_KP_9]},
                        }
                    },
                    {
                        element: Gtk::HBox.new(true, 0),
                        buttons: {
                            :"4" => {keys: [Gdk::Keyval::GDK_4, Gdk::Keyval::GDK_KP_4]},
                            :"5" => {keys: [Gdk::Keyval::GDK_5, Gdk::Keyval::GDK_KP_5]},
                            :"6" => {keys: [Gdk::Keyval::GDK_6, Gdk::Keyval::GDK_KP_6]},
                        }
                    },
                    {
                        element: Gtk::HBox.new(true, 0),
                        buttons: {
                            :"1" => {keys: [Gdk::Keyval::GDK_1, Gdk::Keyval::GDK_KP_1]},
                            :"2" => {keys: [Gdk::Keyval::GDK_2, Gdk::Keyval::GDK_KP_2]},
                            :"3" => {keys: [Gdk::Keyval::GDK_3, Gdk::Keyval::GDK_KP_3]},
                        }
                    },
                    {
                        element: Gtk::HBox.new(true, 0),
                        buttons: {
                            :"0"  => {keys: [Gdk::Keyval::GDK_0, Gdk::Keyval::GDK_KP_0]},
                            Calculator::KEY_DECIMAL    => {keys: [Gdk::Keyval::GDK_period]},
                        }
                    },
                ]
            },
            operators: {
                element: Gtk::VBox.new(false, 0),
                top_right: {
                    element: Gtk::VBox.new(false, 0),
                    rows: [
                        {
                            element: Gtk::HBox.new(true, 0),
                            buttons: {
                                Calculator::KEY_PAREN_LEFT  => {keys: [Gdk::Keyval::GDK_parenleft]},
                                Calculator::KEY_PAREN_RIGHT => {keys: [Gdk::Keyval::GDK_parenright]},
                            },
                        },
                        {
                            element: Gtk::HBox.new(true, 0),
                            columns: [
                                {
                                    element: Gtk::VBox.new(false, 0),
                                    buttons: {
                                        Calculator::KEY_DIVIDE   => {keys: [Gdk::Keyval::GDK_KP_Divide, Gdk::Keyval::GDK_slash]},
                                        Calculator::KEY_MULTIPLY => {keys: [Gdk::Keyval::GDK_KP_Multiply, Gdk::Keyval::GDK_asterisk]}
                                    }
                                },
                                {
                                    element: Gtk::VBox.new(false, 0),
                                    buttons: {
                                        Calculator::KEY_CARAT => {keys: [Gdk::Keyval::GDK_asciicircum]},
                                        Calculator::KEY_PLUS_MINUS => {
                                          keys:      [Gdk::Keyval::GDK_minus, Gdk::Keyval::GDK_KP_Subtract],
                                          modifiers: Gdk::Window::CONTROL_MASK,
                                        },

                                    }
                                }
                            ]
                        }
                    ]
                },
                bottom_right: {
                    element: Gtk::HBox.new(true, 0),
                    columns: [
                        {
                            element: Gtk::VBox.new(false, 0),
                            buttons: {
                                Calculator::KEY_MINUS => {keys: [Gdk::Keyval::GDK_KP_Subtract, Gdk::Keyval::GDK_minus]},
                                Calculator::KEY_PLUS  => {keys: [Gdk::Keyval::GDK_KP_Add, Gdk::Keyval::GDK_plus]}
                            },
                        },
                        {
                            element: Gtk::VBox.new(false, 0),
                            buttons: {Calculator::KEY_EQUALS => {keys: [Gdk::Keyval::GDK_Return, Gdk::Keyval::GDK_equal]}}
                        },
                    ]
                }
            }
        }
    }
  end

  def get_key_masks event
    state = event.state

    masks = {
      ctrl:  state.control_mask?,
      shift: state.shift_mask?,
      mod1:  state.mod1_mask?,
      mod2:  state.mod2_mask?,
      mod3:  state.mod3_mask?,
      mod4:  state.mod4_mask?,
      mod5:  state.mod5_mask?,
      :super => state.super_mask?,
      hyper: state.hyper_mask?,
      meta:  state.meta_mask?,
    }

    masks
  end

end