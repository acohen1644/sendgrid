# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','sendgrid','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'sendgrid'
  s.version = Sendgrid::VERSION
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
# Add your other files here if you make them
  s.files = %w(
bin/sendgrid
lib/sendgrid/version.rb
lib/sendgrid.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','sendgrid.rdoc']
  s.rdoc_options << '--title' << 'sendgrid' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'sendgrid'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','2.0.0')
  s.add_runtime_dependency('mail')
  s.add_runtime_dependency('httparty')
  s.add_runtime_dependency('xml-simple')
end
