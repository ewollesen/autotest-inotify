require 'rubygems'
require 'rake'
 
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "autotest-inotify"
    gem.summary = %Q{Use libinotify (on Linux) instead of filesystem polling.}
    gem.description = %Q{Autotest relies on filesystem polling to detect modifications in source code files. This is expensive for the CPU, harddrive and battery - and unnecesary on Linux with libinotify installed. This gem teaches autotest how to use libinotify.}
    gem.email = "ericw@kill-0.com"
    gem.homepage = "http://kill-0.com/projects/autotest-inotify"
    gem.authors = ["Eric Wollesen"]
#    gem.post_install_message = "\n\e[1;32m" + File.read('PostInstall.txt') + "\e[0m\n"
    gem.files = [
      "lib/autotest/inotify.rb"
    ]
    gem.add_dependency "autotest", ">= 4.2.4"
    gem.add_dependency "rb-inotify"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end
 
require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib'
end
 
Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib'
end
 
require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "autotest-inotify"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
 
task :default => :jeweler
