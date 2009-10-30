#!/usr/bin/ruby
# $Id$

# @file
# A GUI front-end to RI.
#
# @author Mooffie <mooffie@gmail.com>

require 'tk'

module Tkri

  # Returns the pathname of the 'rc' file.
  def self.get_rc_file_path
    basename = RUBY_PLATFORM.index('mswin') ? '_tkrirc' : '.tkrirc'
    if ENV['HOME']
      File.join(ENV['HOME'], basename)
    else
      # Probably Windows with no $HOME set. Dir.pwd sucks but is there
      # anything better to do?  At least the "Help :: About the RC file"
      # screen displays this value, so the user won't be completely clueless...
      File.join(Dir.pwd, basename)
    end
  end

  module DefaultSettings

    COMMAND = {
      # Each platform may use a different command. The commands are indexed by any
      # substring in RUBY_PLATFORM. If none matches the platform, the '__default__' key
      # is used.
      '__default__' => 'qri -f ansi "%s"',

      # The "2>&1" thingy tells UNIX shells to print any error messages to the standard output.
      # This makes it possible to see, inside Tkri, the errors `qri' (or 'ri') happens to emmit
      # (this happens seldom, due to bugs in `qri', so it's not a very critical feature).
      'linux'       => 'qri -f ansi "%s" 2>&1',
      'darwin'      => 'qri -f ansi "%s" 2>&1',

      # And here's the command for MS-Windows.
      # It turns out Windows' CMD.EXE too supports "2>&1". This shell is used on NT-based
      # systems. (In other words, if you're using the good old Windows 98, you'll have to remove
      # this "2>&1").
      'mswin'       => 'qri.bat -f ansi "%s" 2>&1',
    }

    VISUALS = {
      # The '__base__' attibutes are applied for every textfield and textarea.
      # Set the background color and font to whatever you like.
      #
      # Font families are designated by an ordered array of names. The first
      # found on the system will be used. So make sure to put a generic family
      # name (i.e., one of: 'courier', 'times', 'helvetica') at the end to serve
      # as a fallback.
      '__base__' => { :background => '#ffeeff', :font => { :family => ['Bitstream Vera Sans Mono', 'Menlo', 'Monaco', 'Courier'], :size => 10 } },
      'bold'     => { :foreground => 'blue', :is_tag => true },
      'italic'   => { :foreground => '#6b8e23', :is_tag => true }, # greenish
      'code'     => { :foreground => '#1874cd', :is_tag => true }, # blueish
      'header2'  => { :background => '#ffe4b5', :font => { :family => ['Geneva', 'Arial', 'Helvetica'], :size => 12 }, :is_tag => true },
      'header3'  => { :background => '#ffe4b5', :font => { :family => ['Geneva', 'Arial', 'Helvetica'], :size => 14 }, :is_tag => true },
      'keyword'  => { :foreground => 'red', :is_tag => true },
      'search'   => { :background => 'yellow', :is_tag => true },
      'hidden'   => { :elide => true, :is_tag => true},
      'tab_button' => { :padx => 10, :font => { :family => ['Bitstream Vera Sans Mono', 'Menlo', 'Monaco', 'Courier'], :size => 10 } },
      'go_button' => { :padx => 20 },
    }

    BINDINGS = {
      # The keys (e.g. 'b1001') in this hash are named arbitrarily and are completely
      # ignored by Tkri. They exist only to enable you to override certain bindings in
      # your 'rc' file. I'm not going to rename keys, only to add to them (as new
      # bindings are added to newer versions), so you won't have to update your 'rc'
      # file whenever you update Tkri.

      # For the :key syntax, see the Tk manual. The :source is the widget to attach the
      # binding to. The :commands are methods to execute; they're conveniently prefixed
      # by 'interactive_' to enable you to easily locate all of them in the source code.

      'b1001' => { :key => 'Control-q', :source => 'root', :command => 'interactive_quit' },
      'b1002' => { :key => 'Control-t', :source => 'root', :command => 'interactive_new_tab' },
      'b1003' => { :key => 'Control-w', :source => 'root', :command => 'interactive_close_tab' },
      'b1004' => { :key => 'Control-l', :source => 'root', :command => 'interactive_focus_address' },

      # Note: tabs indexes are zero-based.
      'b2001' => { :key => 'Alt-Key-1', :source => 'root', :command => 'interactive_switch_to_tab_0' },
      'b2002' => { :key => 'Alt-Key-2', :source => 'root', :command => 'interactive_switch_to_tab_1' },
      'b2003' => { :key => 'Alt-Key-3', :source => 'root', :command => 'interactive_switch_to_tab_2' },
      'b2004' => { :key => 'Alt-Key-4', :source => 'root', :command => 'interactive_switch_to_tab_3' },
      'b2005' => { :key => 'Alt-Key-5', :source => 'root', :command => 'interactive_switch_to_tab_4' },
      'b2006' => { :key => 'Alt-Key-6', :source => 'root', :command => 'interactive_switch_to_tab_5' },
      'b2007' => { :key => 'Alt-Key-7', :source => 'root', :command => 'interactive_switch_to_tab_6' },
      'b2008' => { :key => 'Alt-Key-8', :source => 'root', :command => 'interactive_switch_to_tab_7' },
      'b2009' => { :key => 'Alt-Key-9', :source => 'root', :command => 'interactive_switch_to_tab_8' },
      'b2010' => { :key => 'Alt-Key-0', :source => 'root', :command => 'interactive_switch_to_tab_9' },

      # For the following we don't use interactive_close_tab because we want to close the
      # tab associated with the button, not the current tab.
      'b1007' => { :key => 'Button-2', :source => 'tabbutton', :command => 'interactive_close_button_tab' },

      # 'Prior' and 'Next' are page up and page down, respectively.
      'b1005' => { :key => 'Control-Key-Prior', :source => 'root', :command => 'interactive_switch_to_prev_tab' },
      'b1006' => { :key => 'Control-Key-Next', :source => 'root', :command => 'interactive_switch_to_next_tab' },

      'b1008' => { :key => 'ButtonRelease-1', :source => 'info', :command => 'interactive_goto_topic_under_mouse' },
      'b1008b' => { :key => 'Control-Button-1', :source => 'info', :command => 'interactive_goto_topic_under_caret_or_selected', :cancel_default => true },
      'b1011' => { :key => 'Key-Return', :source => 'info', :command => 'interactive_goto_topic_under_caret_or_selected', :cancel_default => true },
      'b1012' => { :key => 'Key-Return', :source => 'addressbox', :command => 'interactive_goto_topic_in_addressbox' },
      # If I make the following "ButtonRelease-2" instead, the <PasteSelection>
      # cancellation that follows won't work. Strange.
      'b1009' => { :key => 'Button-2', :source => 'info', :command => 'interactive_goto_topic_under_mouse_in_new_tab', :cancel_default => true },
      # Under X11, Button-2 is also used to paste the selection. So we disable pasting. All
      # because Tk doesn't support read-only text widgets.
      'b1010' => { :key => '<PasteSelection>', :source => 'info',  :cancel_default => true },

      # History.
      'b1013' => { :key => 'ButtonRelease-3', :source => 'info', :command => 'interactive_history_back' },
      'b1014' => { :key => 'Key-BackSpace', :source => 'info', :command => 'interactive_history_back', :cancel_default => true },
      'b1014b' => { :key => 'Alt-Key-Left', :source => 'root', :command => 'interactive_history_back', :cancel_default => true  },
      'b1014c' => { :key => 'Alt-Key-Right', :source => 'root', :command => 'interactive_history_forward', :cancel_default => true  },

      # Tk doesn't support read-only rext widgets. So for every "ascii" global binding we also
      # need to duplicate it on the 'info' widget, :cancel_default'ing it.
      #
      # "Global" bindings are those attached to the 'root' window. For "ascii" bindings make sure
      # to turn on :when_not_tkentry, or else these events will fire up when the key is pressed in
      # the addressbox too (which is a widget of type TkEntry).
      'b1015' => { :key => 'Key-slash', :source => 'root', :command => 'interactive_initiate_search', :when_not_tkentry => true },
      'b1016' => { :key => 'Key-n', :source => 'root', :command => 'interactive_search_next', :when_not_tkentry => true },
      'b1017' => { :key => 'Key-N', :source => 'root', :command => 'interactive_search_prev', :when_not_tkentry => true },
      'b1018' => { :key => 'Key-u', :source => 'root', :command => 'interactive_go_up', :when_not_tkentry => true },
      'b1019' => { :key => 'Key-slash', :source => 'info', :command => 'interactive_initiate_search', :cancel_default => true },
      'b1020' => { :key => 'Key-n', :source => 'info', :command => 'interactive_search_next', :cancel_default => true },
      'b1021' => { :key => 'Key-N', :source => 'info', :command => 'interactive_search_prev', :cancel_default => true },
      'b1022' => { :key => 'Key-u', :source => 'info', :command => 'interactive_go_up', :cancel_default => true },
    }

    # Dump these settings into an 'rc' file.
    def self.dump
      require 'yaml'
      open(Tkri.get_rc_file_path, 'w') do |f|
        f.puts "#"
        f.puts "# The documentation for these settings can be found in this file:"
        f.puts "#   " + File.expand_path(__FILE__)
        f.puts "# Also, see the 'About the `rc` file' under the 'Help' menu."
        f.puts "#"
        f.puts "# You may erase any setting in this file for which you want to use"
        f.puts "# the default value."
        f.puts "#"
        f.puts({ 'command' => COMMAND, 'visuals' => VISUALS, 'bindings' => BINDINGS }.to_yaml)
      end
    end

  end # module DefaultSettings

  class << self
    attr_accessor :the_application
  end

  module Settings
    COMMAND = DefaultSettings::COMMAND.dup
    VISUALS = DefaultSettings::VISUALS.dup
    BINDINGS = DefaultSettings::BINDINGS

    # Load the settings from the 'rc' file. We merge them into the existing settings.
    def self.load
      if File.exist? Tkri.get_rc_file_path
        require 'yaml'
        settings = YAML.load_file(Tkri.get_rc_file_path)
        if settings.instance_of? Hash
          COMMAND.merge!(settings['command']) if settings['command']
          VISUALS.merge!(settings['visuals']) if settings['visuals']
          BINDINGS.merge!(settings['bindings']) if settings['bindings']
        end
      end
    end

    # get_configuration() converts any of the VISUAL hashes, above, to a hash suitable
    # for use in Tk. Corrently, it only converts the :font attribute to a TkFont instance.
    def self.get_configuration(name)
      h = VISUALS[name].dup
      h.delete(:is_tag)
      if h[:font].instance_of? Hash
        h[:font] = h[:font].dup
        if h[:font][:family]
          availables = TkFont.families.map { |s| s.downcase }
          desired = Array(h[:font][:family]).map { |s| s.downcase }
          # Select the first family available on this system.
          h[:font][:family] = (desired & availables).first || 'courier'
        end
        h[:font] = TkFont.new(h[:font])
      end
      return h
    end
  end

HistoryEntry = Struct.new(:topic, :cursor, :yview)

class History
  def initialize
    @arr = []
    @current = -1
  end

  def size
    @arr.size
  end

  def current
    if @current >= 0
      @arr[@current]
    else
      nil
    end
  end

  def back
    if @current > 0
      @current -= 1
    end
    current
  end

  def foreward
    if @current < @arr.size - 1
      @current += 1
    end
  end

  def add(entry)
    @current += 1
    @arr[@current] = entry
    # Adding an entry removes all entries in the "future".
    @arr.slice!(@current + 1, @arr.size)
  end

  def at_beginning
    @current <= 0
  end

  def at_end
    @current == @arr.size - 1;
  end
end

# Attachs Settings::BINDINGS to a certain widget.
#
# Ideally this should be a method of TkWidget, but for some reason widgets don't
# seem to inherit methods I define on TkWidget.
def self.attach_bindings(widget, widget_id_string)
  Tkri::Settings::BINDINGS.each_pair { |ignored_key, b|
    if (b[:source] == widget_id_string)
      keys = Array(b[:key])
      if b[:key] == 'Key-Return'
        keys.push 'Key-KP_Enter'
      end
      keys.each { |key|
        widget.bind(key) { |event|
          skip = (b[:when_not_tkentry] and event.widget.class == TkEntry)
          if !skip
            if b[:command] # Sometimes we're only interested in :cancel_default.
              Tkri.the_application.invoke_command(b[:command], event)
            end
          end
          break if b[:cancel_default]
        }
      }
    end
  }
end

# A Tab encapsulates an @address box, where you type the topic to go to; a "Go"
# button; and an @info box in which to show the topic.
class Tab < TkFrame

  attr_reader :topic

  def initialize(tk_parent, app, configuration = {})
    @app = app
    super(tk_parent, configuration)

    #
    # The address bar
    #
    addressbar = TkFrame.new(self) { |ab|
      pack :side => 'top', :fill => 'x'
      TkButton.new(ab) {
        configure Settings::get_configuration('go_button')
        text 'Go'
        command { app.go }
        pack :side => 'right'
      }
    }
    @address = TkEntry.new(addressbar) {
      configure Settings::get_configuration('__base__')
      configure :width => 30
      pack :side => 'left', :expand => true, :fill => 'both'
    }

    #
    # The info box, where the main text is displayed.
    #
    _frame = self
    @info = TkText.new(self) { |t|
      configure Settings::get_configuration('__base__')
      pack :side => 'left', :fill => 'both', :expand => true
      TkScrollbar.new(_frame) { |s|
        pack :side => 'right', :fill => 'y'
        command { |*args| t.yview *args }
        t.yscrollcommand { |first,last| s.set first,last }
      }
    }

    Settings::VISUALS.each do |name, hash|
      if hash[:is_tag]
        @info.tag_configure(name, Settings::get_configuration(name))
      end
    end

    Tkri.attach_bindings @address, 'addressbox'
    Tkri.attach_bindings @info, 'info'

    @history = History.new
  end

  def interactive_goto_topic_in_addressbox e
    go
  end
  
  def interactive_goto_topic_under_mouse e
    go_xy_word(e.x, e.y)
  end

  def interactive_goto_topic_under_mouse_in_new_tab e
    go_xy_word(e.x, e.y, true)
  end

  def interactive_goto_topic_under_caret_or_selected e
    if get_selection.length > 0
      go get_selection
    else
      go_caret_word()
    end
  end

  # It seems RubyTk doesn't support the the getSelected method for Text widgets.
  # So here's a method of our own to get the selection.
  def get_selection
    begin
      @info.get('sel.first', 'sel.last')
    rescue
      ''
    end
  end

  # Moves the keyboard focus to the address box. Also, selects all the
  # text, like modern GUIs do.
  def focus_address
    @address.selection_range('0', 'end')
    @address.icursor = 'end'
    @address.focus
  end

  def interactive_focus_address e
    focus_address
  end

  # Finds the next occurrence of a word.
  def search_next_word(word)
    @info.focus
    highlight_word word
    cursor = @info.index('insert')
    pos = @info.search_with_length(Regexp.new(Regexp::quote(word), Regexp::IGNORECASE), cursor + ' 1 chars')[0]
    if pos.empty?
      @app.status = 'Cannot find "%s"' % word
    else
      set_cursor(pos)
      if @info.compare(cursor, '>=', pos)
        @app.status = 'Continuing search at top'
      else
        @app.status = ''
      end
    end
  end

  # Finds the previous occurrence of a word.
  def search_prev_word(word)
    @info.focus
    highlight_word word
    cursor = @info.index('insert')
    pos = @info.rsearch_with_length(Regexp.new(Regexp::quote(word), Regexp::IGNORECASE), cursor)[0]
    if pos.empty?
      @app.status = 'Cannot find "%s"' % word
    else
      set_cursor(pos)
      if @info.compare(cursor, '<=', pos)
        @app.status = 'Continuing search at bottom'
      else
        @app.status = ''
      end
    end
  end

  # Highlights a word in the text. Used by the search methods.
  def highlight_word(word)
    return if word.empty?
    @info.tag_remove('search', '1.0', 'end')
    _highlight_word(word.downcase, @info.get('1.0', 'end').downcase, 'search')
  end
  
  def _highlight_word(word_or_regexp, text, tag_name)
    pos = -1
    while pos = text.index(word_or_regexp, pos + 1)
      length = (word_or_regexp.is_a? String) ? word_or_regexp.length : $&.length
      @info.tag_add(tag_name, '1.0 + %d chars' % pos,
                              '1.0 + %d chars' % (pos + length))
    end
  end

  # Go "up". That is, if we're browsing a method, go to the class.
  def interactive_go_up e
    if topic and topic =~ /(.*)(::|#|\.)/
      @app.go $1
    end
  end

  # Navigate to the topic mentioned under the mouse cursor (given by x,y
  # coordinates)
  def go_xy_word(x, y, newtab=false)
    if not newtab and not @info.tag_ranges('sel').empty?
      # We don't want to prohibit selecting text, so we don't trigger
      # navigation if some text is selected. (Remember, this method is called
      # upon releasing the mouse button.)
      return
    end
    go_word('@' + x.to_s + ',' + y.to_s, newtab)
  end

  # Navigate to the topic mentioned under the caret.
  def go_caret_word(newtab=false)
    go_word('insert', newtab)
  end

  def go_word(position, newtab=false)
    if (word = get_word(position))
      @app.go word, newtab
    end
  end

  # Returns the section (the header) the cursor is in.
  def get_previous_header cursor
    ret = @info.rsearch_with_length(/[\r\n]\w[^\r\n]*/, cursor)
    if !ret[0].empty? and @info.compare(cursor, '>=', ret[0])
      return ret[2].strip
    end
  end

  # Returns the first class mentioned before the cursor.
  def get_previous_class cursor
    ret = @info.rsearch_with_length(/[A-Z]\w*/, cursor)
    return ret[0].empty? ? nil : ret[2]
  end

  # Get the "topic" at a certain postion.
  #
  # The 'position' paramter is an expression that can be, e.g., "insert"
  # for the current caret position; or "@x,y" for the mouse poisition.
  def get_word(position)
    line = @info.get(position + ' linestart', position + ' lineend')
    pos  = @info.get(position + ' linestart', position).length

    line = ' ' + line + '  '
    pos += 1
    
    if line[pos,1] == ' '
      # If the user clicks a space between words, or after end of line, abort.
      return nil
    end
    
    a = pos
    a -= 1 while line[a-1,1] !~ /[ (]/
    z = pos
    z += 1 while line[z+1,1] !~ /[ ()]/
    word = line[a..z]

    # Get rid of English punctuation.
    word.gsub!(/[,.:;]$/, '')

    # Get rid of italic, bold, and code markup.
    if word =~ /^(_|\*|\+).*\1$/
      word = word[1...-1]
      a += 1
    end

    a -= 1 # Undo the `line = ' ' + line` we did previously.
    @info.tag_add('keyword', '%s linestart + %d chars' % [ position, a ],
                             '%s linestart + %d chars' % [ position, a+word.length ])
    word.strip!
    
    return nil if word.empty?
    return nil if word =~ /^-+$/ # A special case: a line of '-----'

    case get_previous_header(position)
    when 'Instance methods:'
      word = topic + '#' + word
    when 'Class methods:'
      word = topic + '::' + word
    when 'Includes:'
      word = get_previous_class(position) + '#' + word if not word =~ /^[A-Z]/
    end

    return word
  end

  # Sets the text of the @info box, converting ANSI escape sequences to Tk
  # tags.
  def set_ansi_text(text)
    text = text.dup
    ansi_tags = {
      # The following possibilities were taken from /usr/lib/ruby/1.8/rdoc/ri/ri_formatter.rb
      '1'    => 'bold',
      '33'   => 'italic',
      '36'   => 'code',
      '4;32' => 'header2',
      '32'   => 'header3',
    }
    ranges = []
    while text =~ /\x1b\[([\d;]+)m ([^\x1b]*) \x1b\[0?m/x
      start      = $`.length
      length     = $2.length
      raw_length = $&.length
      text[start, raw_length] = $2
      ranges << { :start => start, :length => length, :tag => ansi_tags[$1] }
    end

    @info.delete('1.0', 'end')
    @info.insert('end', text)

    ranges.each do |range|
      if range[:tag]
        @info.tag_add(range[:tag], '1.0 + %d chars' %  range[:start],
                                   '1.0 + %d chars' % (range[:start] + range[:length]))
      end
    end
    # Hide any remaining sequences. This may happen because our previous regexp
    # (or any regexp) can't handle nested sequences.
    _highlight_word(/\x1b\[([\d;]*)m/, text, 'hidden')
  end

  # Allow for some shortcuts when typing topics...
  def fixup_topic(topic)
    case topic
    when 'S', 's', 'string'
      'String'
    when 'A', 'a', 'array'
      'Array'
    when 'H', 'h', 'hash'
      'Hash'
    when 'File::new'
      # See qri bug at http://rubyforge.org/tracker/index.php?func=detail&aid=23504&group_id=2545&atid=9811
      'File#new'
    else
      topic
    end
  end

  # Navigates to some topic.
  def go(topic=nil)
    topic = (topic || @address.get).strip
    return if topic.empty?
    @topic = fixup_topic(topic)
    # First, save the cursor position in the current history entry.
    store_in_history
    # Next, add a new entry to the history.
    @history.add HistoryEntry.new(@topic, nil, nil)
    # Finally, load the topic.
    _load_topic @topic
  end

  # Call this method before switching to another topic. This
  # method saves the cursor position in the history.
  def store_in_history
    if current = @history.current
      current.cursor = @info.index('insert')
      current.yview = @info.yview[0]
    end
  end

  # Call this method after moving fack and forth in the history.
  # This method restores the topic and cursor position recorded
  # in the current history entry.
  def restore_from_history
    if current = @history.current
      @topic = current.topic
      _load_topic(topic) do
        @info.yview_moveto current.yview
        set_cursor current.cursor
      end
    end
  end

  def _load_topic(topic)
    @app.status = 'Loading "%s"...' % topic
    @address.delete('0', 'end')
    @address.insert('end', topic)
    focus_address
    # We need to give our GUI a chance to redraw itself, so we run the
    # time-consuming 'ri' command "in the next go".
    TkAfter.new 100, 1 do
      ri = @app.fetch_ri(topic)
      set_ansi_text(ri)
      @app.refresh_tabsbar
      @app.status = ''
      @info.focus
      set_cursor '1.0'
      yield if block_given?
    end.start
  end
  
  # Navigate to the previous topic in history.
  def interactive_history_back e
    if not @history.at_beginning
      store_in_history
      @history.back
      restore_from_history
    end
  end

  # Navigate to the next topic in history.
  def interactive_history_forward e
    if not @history.at_end
      store_in_history
      @history.foreward
      restore_from_history
    end
  end

  # Sets @info's caret position. Scroll the view if needed.
  def set_cursor(pos)
    @info.mark_set('insert', pos)
    @info.see(pos)
  end

  def new?
    not @topic
  end

  def show
    pack :fill => 'both', :expand => true
  end

  def hide
    pack_forget
  end
end

# The tabsbar holds the buttons used to switch among the tabs.
class Tabsbar < TkFrame

  def initialize(tk_parent, tabs, configuration = {})
    @tabs = tabs
    super(tk_parent, configuration)
    @buttons = []
    build_buttons
  end

  def set_current_tab_by_index new
    @buttons.each_with_index do |b, i|
      b.relief = (i == new) ? 'sunken' : 'raised'
    end
    @tabs.set_current_tab_by_index new
  end

  def build_buttons
    @buttons.each { |b| b.destroy }
    @buttons = []
    @tabs.each_with_index do |tab, i|
      b = TkButton.new(self, :text => (tab.topic || '<new>')).pack :side => 'left'
      b.configure Settings::get_configuration('tab_button')
      b.command { set_current_tab_by_index i }
      Tkri.attach_bindings b, 'tabbutton'
      @buttons << b
    end
    plus = TkButton.new(self, :text => '+').pack :side => 'left', :padx => 10
    plus.configure Settings::get_configuration('tab_button')
    plus.command { @tabs.new_tab }
    @buttons << plus
    set_current_tab_by_index @tabs.current_tab_as_index
  end

  def interactive_close_button_tab e
    if idx = @buttons.index(e.widget)
      @tabs.close @tabs.get(idx)
    end
  end
end

# A 'Tabs' object holds several child objects of class 'Tab' and switches their
# visibility so that only one is visible at one time.
class Tabs < TkFrame

  include Enumerable

  def initialize(tk_parent, app, configuration = {})
    @app = app
    super(tk_parent, configuration)
    @tabs = []
    new_tab
  end

  def new_tab
    tab = Tab.new(self, @app)
    tab.focus_address
    @tabs << tab
    set_current_tab_by_index(@tabs.size - 1, true)
  end

  def interactive_new_tab e
    new_tab
  end

  def get(i)
    @tabs[i]
  end

  def close(tab)
    if (@tabs.size > 1 and i = @tabs.index(tab))
      @tabs.delete_at i
      tab.destroy
      set_current_tab_by_index(@current - 1) if @current >= i and @current > 0
      @app.refresh_tabsbar
    end
  end

  def set_current_tab_by_index(tab_index, refresh=false)
    if tab_index < @tabs.size
      self.each_with_index do |tab, i|
        if i == tab_index;
          tab.show
          # Unless we focus on the new tab, the focus may stay at the old tab's address box.
          tab.focus
        else
          tab.hide
        end
      end
      @current = tab_index
    end
    @app.refresh_tabsbar if refresh
  end

  def switch_to(tab_index)
    set_current_tab_by_index(tab_index, true)
  end

  def interactive_switch_to_tab_0 e; switch_to 0; end
  def interactive_switch_to_tab_1 e; switch_to 1; end
  def interactive_switch_to_tab_2 e; switch_to 2; end
  def interactive_switch_to_tab_3 e; switch_to 3; end
  def interactive_switch_to_tab_4 e; switch_to 4; end
  def interactive_switch_to_tab_5 e; switch_to 5; end
  def interactive_switch_to_tab_6 e; switch_to 6; end
  def interactive_switch_to_tab_7 e; switch_to 7; end
  def interactive_switch_to_tab_8 e; switch_to 8; end
  def interactive_switch_to_tab_9 e; switch_to 9; end

  def interactive_switch_to_prev_tab e
    new = current_tab_as_index - 1
    new = @tabs.size - 1 if new < 0
    set_current_tab_by_index(new, true)
  end

  def interactive_switch_to_next_tab e
    new = current_tab_as_index + 1
    new = 0 if new >= @tabs.size
    set_current_tab_by_index(new, true)
  end

  def current_tab_as_index
    return @current
  end

  def current_tab
    @tabs[current_tab_as_index]
  end

  def interactive_close_tab e
    close current_tab
  end

  def each
    @tabs.each do |tab|
      yield tab
    end
  end
  
end

class App


  def initialize
    @root = root = TkRoot.new { title 'Tkri' }
    @search_word = nil
    
    Tkri.the_application = self
    
    Settings.load
   
    menu_spec = [
      [['File', 0],
        ['New tab', proc { execute 'interactive_new_tab' }, 0, 'Ctrl+T' ],
        ['Close tab', proc { execute 'interactive_close_tab' }, 0, 'Ctrl+W' ],
        '---',
        ['Quit', proc { execute 'interactive_quit' }, 0, 'Ctrl+Q' ]],
      [['Search', 0],
        ['Search', proc { execute 'interactive_initiate_search' }, 0, '/'],
        ['Repeat search', proc { execute 'interactive_search_next' }, 0, 'n'],
        ['Repeat backwards', proc { execute 'interactive_search_prev' }, 7, 'N']],
      # The following :menu_name=>'help' has no effect, but it should have...
      # probably a bug in RubyTK.
      [['Help', 0, { :menu_name => 'help' }],
        ['Overview', proc { help_overview }, 0],
        ['Key bindings', proc { help_key_bindings }, 0],
        ['Tips and tricks', proc { help_tips_and_tricks }, 0],
        ['About the $HOME/.tkrirc file', proc { help_rc }, 0],
        ['Known issues', proc { help_known_issues }, 0]],
    ]
    TkMenubar.new(root, menu_spec).pack(:side => 'top', :fill => 'x')

    @tabs = Tabs.new(root, self) {
      pack :side => 'top', :fill => 'both', :expand => true
    }
    @tabsbar = Tabsbar.new(root, @tabs) {
      pack :side => 'top', :fill => 'x', :before => @tabs
    }
    @statusbar = TkLabel.new(root, :anchor => 'w') {
      pack :side => 'bottom', :fill => 'x'
    }

    Tkri::attach_bindings root, 'root'
  end

  # Invokes an "interactive" command (see Settings::BINDINGS).
  # The command is searched in App, Tabs, Tabsbar, Tab, in this order. 
  def invoke_command(command, event)
    possible_targets = [self, @tabs, @tabsbar, @tabs.current_tab]
    possible_targets.each { |target|
      if target.respond_to?(command, true)
        target.send(command, event)
        break
      end
    }
  end

  # Execute is the same as invoke_command() except that we don't
  # provide an event. It's existence is for aesthetics' sake only.
  # It is used in menus.
  def execute(command)
    invoke_command(command, nil)
  end

  def interactive_quit e
    exit
  end

  def run
    Tk.mainloop
  end
  
  # Navigates to some topic. This method simply delegates to the current tab.
  def go(topic=nil, newtab=false)
    @tabs.new_tab if newtab and not @tabs.current_tab.new?
    @tabs.current_tab.go topic
  end

  # Sets the text to show in the status bar.
  def status=(status)
    @statusbar.configure(:text => status)
  end

  def refresh_tabsbar
    @tabsbar.build_buttons if @tabsbar
  end

  def interactive_search_prev e
    if @search_word
      @tabs.current_tab.search_prev_word @search_word
    end
  end

  def interactive_search_next e
    if @search_word
      @tabs.current_tab.search_next_word @search_word
    else
      interactive_initiate_search nil
    end
  end

  def interactive_initiate_search e
    self.status = 'Type the string to search'
    entry = TkEntry.new(@root).pack(:fill => 'x').focus
    ['Key-Return', 'Key-KP_Enter'].each do |event|
      entry.bind(event) {
        self.status = ''
        @search_word = entry.get
        @tabs.current_tab.search_next_word entry.get
        entry.destroy
      }
    end
    ['Key-Escape', 'FocusOut'].each do |event|
      entry.bind(event) {
        self.status = ''
        entry.destroy
      }
    end
    entry.bind('KeyRelease') {
      @tabs.current_tab.highlight_word entry.get
    }
  end

  # Executes the 'ri' command and returns its output.
  def fetch_ri topic
    if !@ri_cache
      @ri_cache = {}
      @cached_topics = []
    end

    return @ri_cache[topic] if @ri_cache[topic]

    command = Settings::COMMAND.select { |k,v| RUBY_PLATFORM.index(k) }.first.to_a[1] || Settings::COMMAND['__default__']
    text = Kernel.`(command % topic)  # `
    if $? != 0
      text += "\n" + "ERROR: Failed to run the command '%s' (exit code: %d). Please make sure you have this command in your PATH.\n\nYou may wish to modify this program's source (%s) to update the command to something that works on your system." % [command % topic, $?, $0]
    else
      if text == "nil\n"
        text = 'Topic "%s" not found.' % topic
      end
      @ri_cache[topic] = text
      @cached_topics << topic
    end

    # Make the "Multiple choices" output easier to read.
    if text.match /Multiple choices/
      text.gsub! /,\s+/, "\n"
      text.gsub! /^ */,  ""
      text.gsub! /\n/,   "\n     "
    end

    # Remove the oldest topic from the cache
    if @cached_topics.length > 20
      @ri_cache.delete @cached_topics.shift
    end
    
    return text
  end

  def helpbox(title, text)
    w = TkToplevel.new(:title => title)
    t = TkText.new(w, :height => text.count("\n"), :width => 80).pack.insert('1.0', text)
    t.configure Settings::get_configuration('__base__')
    TkButton.new(w, :text => 'Close', :command => proc { w.destroy }).pack
  end

  def help_overview
    helpbox('Help: Overview', <<EOS)
ABOUT

Tkri (pronounce TIK-ri) is a GUI front-end to the 'ri', or
'qri', executables. By default it uses 'qri', which is part
of the Fast-RI package.

Tkri displays the output of that program in a window where
each work is "hyperlinked".

USAGE

Launch tkri by typing 'tkri' at the operating system prompt. You
can provide a starting topic as an argument on the command line.
Inside the application, type the topic you wish to go to at the
address bar, or click on a word in the main text.
EOS
  end

  def help_key_bindings
    helpbox('Help: Key bindings', <<EOS)
These are the *default* bindings. They are configurable via the 'rc' file.

Left mouse button
    Navigate to the topic under the cursor.
Ctrl + Left mouse button
    Navigate to the topic selected (marked) with the mouse.
Middle mouse button
    Navigate to the topic under the cursor. Opens in a new tab.
Right mouse button, Backspace, Alt+Left
    Move back in the history.
Alt+Right
    Move foreward in the history.
Ctrl+W. Or middle mouse button, on a tab button
    Close the tab (unless this is the only tab).
Ctrl+L
    Move the keyboard focus to the "address" box, where you can type a topic.
Ctrl+T
    New tab.
Alt+1 .. Alt+9, Ctrl+PgUp, Ctrl+PgDn
    Swith to a certain tab, or to the next/previous one.
u
    Goes "up" one level. That is, if you're browsing Module::Class#method,
    you'll be directed to Module::Class. Press 'u' again for Module.
Enter
    Go to the topic under the caret, or, if some text is selected, to the
    topic selected.
/
    Find string in page. 
n, N
    Jump to next/previous finds.
EOS
  end

  def help_tips_and_tricks
    helpbox('Help: Tips and tricks', <<EOS)
Some random tips:

Type '/' to quickly highlight a string in the page. (If the
string happens to be off-screen, hit ENTER to jump to it.)

Ctrl+L is probably the fastest way to move the keyboard
focus to the "address box".

The references for "Hash", "Array" and "String" are the most
sought-after, so instead of typing their full name in the address
box you can just type the letters h, a or s, respectively.

You can type the topic(s) directly on the command line;
e.g., "tkri Array.flatten sort_by"

Left-clicking on a word doesn't yet send you to a new page. It's
*releasing* the button that sends you there. This makes it possible to
select pieces of code: left-click, then drag, then release; since some
text is now selected, Tkri figures out that's all you wanted.

When using Enter to go to a selected (marked) topic, note that it's easier
to hit the Enter of the keypad, with your thumb, because it's near the
mouse (provided you're right-handed). As a bonus, you can navigate with one
hand only.
EOS
  end

  def help_rc
    helpbox('Help: RC', <<EOS)
Tkri has some settings. E.g., the colors and fonts it uses.

These settings are hard-coded in the source code. But you can
override them by having an 'rc' file in your home folder. On
your system this file is here:

    #{Tkri.get_rc_file_path}

(If it's at a weird place, set your $HOME environment variable.)

Of course, you're a busy person and don't have time to write
this file from scratch. So you're going to tell Tkri to write
this file for you; When you type:

    tkri --dump-rc

you're telling Tkri to dump all its default settings into that
file. Then edit this file to your liking using your text editor.
Finally, run tkri; it will automatically merge the settings from
this file onto the hard-coded ones.
EOS
  end

  def help_known_issues
    helpbox('Help: Known issues', <<EOS)
Here's a list of known issues / bugs:

ON THE WINDOWS PLATFORM:

* The mouse wheel works only if the keyboard focus is in the
  textarea. That's unfortunate. It's a Tk issue, not Tkri's.

* If your $HOME variable contains non-ASCII charcaters, Tkri
  seems not to be able to deal with the 'rc' file. It's a Ruby
  issue(?).

ALL PLATFORMS:

* No known issues.
EOS
  end
end

end # module Tkri
