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

    TAGS = {
      # The '__base__' attibutes are applied for every textfield and textarea.
      # Set the background color and font to whatever you like.
      #
      # Font families are designated by an ordered array of names. The first
      # found on the system will be used. So make sure to put a generic family
      # name (i.e., one of: 'courier', 'times', 'helvetica') at the end to serve
      # as a fallback.
      '__base__' => { :background => '#ffeeff', :font => { :family => ['Bitstream Vera Sans Mono', 'courier'], :size => 10 } },
      'bold'     => { :foreground => 'blue' },
      'italic'   => { :foreground => '#6b8e23' }, # greenish
      'code'     => { :foreground => '#1874cd' }, # blueish
      'header2'  => { :background => '#ffe4b5', :font => { :family => ['helvetica'], :size => 16 } },
      'header3'  => { :background => '#ffe4b5', :font => { :family => ['helvetica'], :size => 16 } },
      'keyword'  => { :foreground => 'red' },
      'search'   => { :background => 'yellow' },
      'hidden'   => { :elide => true },
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
        f.puts({ 'command' => COMMAND, 'tags' => TAGS }.to_yaml)
      end
    end

  end # module DefaultSettings

  module Settings
    COMMAND = DefaultSettings::COMMAND.dup
    TAGS = DefaultSettings::TAGS.dup

    # Load the settings from the 'rc' file. We merge them into the existing settings.
    def self.load
      if File.exist? Tkri.get_rc_file_path
        require 'yaml'
        settings = YAML.load_file(Tkri.get_rc_file_path)
        if settings.instance_of? Hash
          COMMAND.merge!(settings['command']) if settings['command']
          TAGS.merge!(settings['tags']) if settings['tags']
        end
      end
    end
  end

HistoryEntry = Struct.new(:topic, :cursor, :yview)

# hash_to_configuration() converts any of the TAG hashes, above, to a hash suitable
# for use in Tk. Corrently, it only converts the :font attribute to a TkFont instance.
def self.hash_to_configuration(hash)
  ret = hash.dup
  if ret[:font].instance_of? Hash
    if ret[:font][:family]
      ret[:font] = ret[:font].dup
      availables = TkFont.families.map { |s| s.downcase }
      # Select the first family available on this system.
      Array(ret[:font][:family]).each { |family|
        if availables.include? family.downcase
          ret[:font][:family] = family
          break
        end
      }
    end
    ret[:font] = TkFont.new(ret[:font])
  end
  return ret
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
        text 'Go'
        command { app.go }
        pack :side => 'right'
      }
    }
    @address = TkEntry.new(addressbar) {
      configure Tkri::hash_to_configuration(Settings::TAGS['__base__'])
      configure :width => 30
      pack :side => 'left', :expand => true, :fill => 'both'
    }

    #
    # The info box, where the main text is displayed.
    #
    _frame = self
    @info = TkText.new(self) { |t|
      configure Tkri::hash_to_configuration(Settings::TAGS['__base__'])
      pack :side => 'left', :fill => 'both', :expand => true
      TkScrollbar.new(_frame) { |s|
        pack :side => 'right', :fill => 'y'
        command { |*args| t.yview *args }
        t.yscrollcommand { |first,last| s.set first,last }
      }
    }

    Settings::TAGS.each do |name, conf|
      @info.tag_configure(name, conf)
    end

    # Key and mouse bindings
    @address.bind('Key-Return')   { go }
    @address.bind('Key-KP_Enter') { go }
    @info.bind('ButtonRelease-1') { |e| go_xy_word(e.x, e.y) }
    # If I make the following "ButtonRelease-2" instead, the <PasteSelection>
    # cancellation that follows won't work. Strange.
    @info.bind('Button-2')        { |e| go_xy_word(e.x, e.y, true) }
    @info.bind('Key-Return')      { go_caret_word(); break }
    @info.bind('Key-KP_Enter')    { go_caret_word(); break }
    @info.bind('ButtonRelease-3') { |e| back }
    @info.bind('Key-BackSpace')   { |e| back; break }
  
    # Tk doesn't support "read-only" text widget. We "disable" the following
    # keys explicitly (using 'break'). We also forward these search keys to
    # @app.
    @info.bind('<PasteSelection>') { break }
    @info.bind('Key-slash') { @app.search;      break }
    @info.bind('Key-n')     { @app.search_next; break }
    @info.bind('Key-N')     { @app.search_prev; break }

    @history = []
  end

  # Moves the keyboard focus to the address box. Also, selects all the
  # text, like modern GUIs do.
  def focus_address
    @address.selection_range('0', 'end')
    @address.icursor = 'end'
    @address.focus
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
  def go(topic=nil, skip_history=false)
    topic = (topic || @address.get).strip
    return if topic.empty?
    if @topic and not skip_history
      # Push current topic into history.
      @history << HistoryEntry.new(@topic, @info.index('insert'), @info.yview[0])
    end
    @topic = fixup_topic(topic)
    @app.status = 'Loading "%s"...' % @topic
    @address.delete('0', 'end')
    @address.insert('end', @topic)
    focus_address
    # We need to give our GUI a chance to redraw itself, so we run the
    # time-consuming 'ri' command "in the next go".
    TkAfter.new 100, 1 do
      ri = @app.fetch_ri(@topic)
      set_ansi_text(ri)
      @app.refresh_tabsbar
      @app.status = ''
      @info.focus
      set_cursor '1.0'
      yield if block_given?
    end.start
  end

  # Navigate to the previous topic viewed.
  def back
    if (entry = @history.pop)
      go(entry.topic, true) do
        @info.yview_moveto entry.yview
        set_cursor entry.cursor
      end
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

  def set_current_tab new
    @buttons.each_with_index do |b, i|
      b.relief = (i == new) ? 'sunken' : 'raised'
    end
    @tabs.set_current_tab new
  end

  def build_buttons
    @buttons.each { |b| b.destroy }
    @buttons = []

    @tabs.each_with_index do |tab, i|
      b = TkButton.new(self, :text => (tab.topic || '<new>')).pack :side => 'left'
      b.command { set_current_tab i }
      b.bind('Button-3') { @tabs.close tab }
      @buttons << b
    end

    plus = TkButton.new(self, :text => '+').pack :side => 'left'
    plus.command { @tabs.new_tab }
    @buttons << plus

    set_current_tab @tabs.get_current_tab
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
    set_current_tab(@tabs.size - 1)
    @app.refresh_tabsbar
  end

  def close(tab)
    if (@tabs.size > 1 and i = @tabs.index(tab))
      @tabs.delete_at i
      tab.destroy
      set_current_tab(@current - 1) if @current >= i and @current > 0
      @app.refresh_tabsbar
    end
  end

  def set_current_tab(new)
    self.each_with_index do |tab, i|
      if i == new; tab.show; else tab.hide; end
    end
    @current = new
  end

  def get_current_tab
    return @current
  end

  def current
    @tabs[get_current_tab]
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
    
    Settings.load
   
    menu_spec = [
      [['File', 0],
        ['Close tab', proc { @tabs.close @tabs.current }, 0, 'Ctrl+W' ],
        '---',
        ['Quit', proc { exit }, 0, 'Ctrl+Q' ]],
      [['Search', 0],
        ['Search', proc { search }, 0, '/'],
        ['Repeat search', proc { search_next }, 0, 'n'],
        ['Repeat backwards', proc { search_prev }, 7, 'N']],
      # The following :menu_name=>'help' has no effect, but it should have...
      # probably a bug in RubyTK.
      [['Help', 0, { :menu_name => 'help' }],
        ['Overview', proc { help_overview }, 0],
        ['Key bindings', proc { help_key_bindings }, 0],
        ['Tips and tricks', proc { help_tips_and_tricks }, 0],
        ['About the $HOME/.tkrirc file', proc { help_rc }, 0]],
    ]
    TkMenubar.new(root, menu_spec).pack(:side => 'top', :fill => 'x')

    root.bind('Control-q') { exit }
    root.bind('Control-w') { @tabs.close @tabs.current }
    root.bind('Control-l') { @tabs.current.focus_address }
   
    { 'Key-slash' => 'search',
      'Key-n'     => 'search_next',
      'Key-N'     => 'search_prev',
    }.each do |event, method|
      root.bind(event) { |e|
        send(method) if e.widget.class != TkEntry
      }
    end

    @tabs = Tabs.new(root, self) {
      pack :side => 'top', :fill => 'both', :expand => true
    }
    @tabsbar = Tabsbar.new(root, @tabs) {
      pack :side => 'top', :fill => 'x', :before => @tabs
    }
    @statusbar = TkLabel.new(root, :anchor => 'w') {
      pack :side => 'bottom', :fill => 'x'
    }
  end

  def run
    Tk.mainloop
  end
  
  # Navigates to some topic. This method simply delegates to the current tab.
  def go(topic=nil, newtab=false)
    @tabs.new_tab if newtab and not @tabs.current.new?
    @tabs.current.go topic
  end

  # Sets the text to show in the status bar.
  def status=(status)
    @statusbar.configure(:text => status)
  end

  def refresh_tabsbar
    @tabsbar.build_buttons if @tabsbar
  end
  
  def search_prev
    if @search_word
      @tabs.current.search_prev_word @search_word
    end
  end
  
  def search_next
    if @search_word
      @tabs.current.search_next_word @search_word
    else
      search
    end
  end

  def search
    self.status = 'Type the string to search'
    entry = TkEntry.new(@root).pack(:fill => 'x').focus
    ['Key-Return', 'Key-KP_Enter'].each do |event|
      entry.bind(event) {
        self.status = ''
        @search_word = entry.get
        @tabs.current.search_next_word entry.get
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
      @tabs.current.highlight_word entry.get
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
    ri = Kernel.`(command % topic)  # `
    if $? != 0
      ri += "\n" + "ERROR: Failed to run the command '%s' (exit code: %d). Please make sure you have this command in your PATH.\n\nYou may wish to modify this program's source (%s) to update the command to something that works on your system." % [command % topic, $?, $0]
    else
      if ri == "nil\n"
        ri = 'Topic "%s" not found.' % topic
      end
      @ri_cache[topic] = ri
      @cached_topics << topic
    end

    # Remove the oldest topic from the cache
    if @cached_topics.length > 10
      @ri_cache.delete @cached_topics.shift
    end
    
    return ri
  end

  def helpbox(title, text)
    w = TkToplevel.new(:title => title)
    t = TkText.new(w, :height => text.count("\n"), :width => 80).pack.insert('1.0', text)
    t.configure Tkri::hash_to_configuration(Settings::TAGS['__base__'])
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
Left mouse button
    Navigate to the topic under the cursor.
Middle mouse button
    Navigate to the topic under the cursor. Opens in a new tab.
Right mouse button
    Move back in the history. 
Ctrl+W. Or right mouse button, on a tab button
    Close the tab (unless this is the only tab).
Ctrl+L
    Move the keyboard focus to the "address" box, where you can type a topic.
/
    Find string in page.
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
*releasing* the button that sends you. This makes it possible to
select pieces of code: left-click, then drag, then release; since some
text is now selected, Tkri figures out that's all you wanted.

Right-clicking moves you backward in history. To move forward,
just hit ENTER. This works because the 'back' command restores the
caret position as well. Since you're probably holding your mouse,
you'll find it much more convenient to hit, with your thumb, the
ENTER on the keypad.
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
end

end # module Tkri
