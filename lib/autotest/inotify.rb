# Extend autotest with inotify goodness

require "ruby-debug"
require "rubygems"
require "autotest"
require "rbconfig"
require "rb-inotify"

module Autotest::Inotify

  Autotest.add_hook :initialize do
    #override_autotest_methods_if_running_linux
    class ::Autotest
      remove_method :find_files_to_test
      remove_method :wait_for_changes

      def wait_for_changes
        return # this is now a no-op
      end

      def find_files_to_test(files=nil)
        #debugger
        if first_time_run?
          files = find_files
          setup_notifier(files)
          find_files_to_test_first_run(files)
        else
          @updated = {}
          hook :waiting
          $stderr.puts "blocking until modification detected"
          @notifier.process
          hook :updated, @updated
          extract_test_files_from_modified_files(@updated).each do |filename|
            $stderr.puts "need to test #{filename}"
            self.files_to_test[filename]
          end
        end
        return Time.now
      end

      def first_time_run?
        self.last_mtime.to_i.zero?
      end

      def setup_notifier(files)
        @notifier = INotify::Notifier.new
        files.keys.each do |filename|
          @notifier.watch(filename, :modify) do |event| 
            mark_file_as_modified(event)
          end
        end
      end

      def mark_file_as_modified(event)
        @updated[event.absolute_name] = Time.now
      end

      def find_files_to_test_first_run(files)
        extract_test_files_from_modified_files(files).each do |filename|
          self.files_to_test[filename]
        end
      end

      def extract_test_files_from_modified_files(files)
        files.map {|filename , m| test_files_for(filename)}.flatten.uniq
      end

    end
  end


  private

  def override_autotest_methods_if_running_linux
    if running_linux?
      setup_inotify_instance
      override_find_files_to_test
    end
  end

  def running_linux?
    /linux/i === RbConfig::CONFIG["host_os"]
  end

  # def setup_inotify_instance
  #   class ::Autotest
  #     def setup_inotify
  #       @notifier = INotify::Notifier.new
  #       find_files.keys.each do |filename|
  #         @notifier.watch(filename, :modify)
  #       end
  #     end
  #   end
  # end

  # def override_find_files_to_test
  #   class ::Autotest
  #     remove_method :find_files_to_test

  #     def find_files_to_test(files=find_files)
  #       setup_notifier unless @notifier
  #       @notifier.process
  #       return true
  #     end
  #   end
  # end

end
