require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name          = 'tkri'
  s.version       = '0.9.4'
  s.author        = 'Mooffie'
  s.email         = 'mooffie@gmail.com'
  s.platform      = Gem::Platform::RUBY
  s.rubyforge_project = 'tkri'
  s.homepage      = 'http://rubyforge.org/projects/tkri/'
  s.summary       = "GUI front-end to FastRI's or RI's executables."
  s.files         = ['README', 'lib/tkri.rb', 'bin/tkri']
  s.bindir        = 'bin'
  s.executables   = ['tkri']
  s.require_path  = 'lib' 
  s.add_dependency('fastri', '>= 0.3')
end

if $0 == __FILE__
  Gem::Builder.new(spec).build
end
