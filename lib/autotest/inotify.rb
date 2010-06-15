# Extend autotest with inotify goodness

require "rubygems"
require "autotest"
require "rbconfig"
require "rb-inotify"

Autotest.add_hook :initialize do
  include Autotest::Inotify
  setup_inotify_if_running_linux
end

##
# Autotest::Inofity
#
# == FEATURES:
# * Use Linux's inotify instead of filesystem polling
#
# == SYNOPSIS:
# Add the following to your ~/.autotest file:
# require "autotest/inotify"
module Autotest::Inotify

  private

  def setup_inotify_if_running_linux
    if running_linux?
      override_autotest_methods
    end
  end

  def running_linux?
    /linux/i === RbConfig::CONFIG["host_os"]
  end

  def override_autotest_methods
    ::Autotest.class_eval do
      remove_method :find_files_to_test
      remove_method :wait_for_changes

      def wait_for_changes
        @changed_files = {}
        hook :waiting
        @notifier.process while @changed_files.empty?
      end

      def find_files_to_test(files=nil)
        if first_time_run?
          setup_inotify
          unless options[:no_full_after_start]
            select_all_tests
          end
        else
          p @changed_files if $v
          hook :updated, @changed_files
          select_tests_for_changed_files
        end
        return Time.now
      end
    end
  end

  def first_time_run?
    @notifier.nil?
  end

  def setup_inotify
    @notifier = INotify::Notifier.new
    files = self.find_files.keys
    dirs = files.map{|f| File.dirname( f )}.uniq
    # Watch directories to catch delete/move swap patterns as well as direct
    # modifications.  This handles, e.g. :w in vim.
    dirs.each do |dir|
      @notifier.watch( dir, :all_events ) do |event|
        if  event.flags.include? :modify and
            files.include? event.absolute_name 
          handle_file_event( event )
        end
      end
    end
  end

  def handle_file_event(event)
    @changed_files[event.absolute_name] = Time.now
  end

  def select_all_tests
    map_files_to_tests_for(find_files).each do |filename|
      self.files_to_test[filename]
    end
  end

  def map_files_to_tests_for(files)
    files.map {|filename, mtime| test_files_for(filename)}.flatten.uniq
  end

  def select_tests_for_changed_files
    map_files_to_tests_for(@changed_files).each do |filename|
      self.files_to_test[filename]
    end
  end

end
