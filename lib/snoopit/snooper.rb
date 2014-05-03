require 'json'
module Snoopit
  class Snooper

    attr :snoopies

    def initialize(logger=nil, log_level=::Logger::INFO)
      @snoopies = []
      Snoopit::Logger.create_logger(logger) unless logger.nil?
      Snoopit.logger.level = log_level
    end

    # Load the configuration from a file
    # @param snoopies_file [String] path to file
    def load_file(snoopies_file)
      raise ArgumentError.new "Invalid Snooper JSON File: #{snoopies_file}" if (snoopies_file.nil?) || (! File.exist? snoopies_file)
      load_array JSON.parse(IO.read(snoopies_file))
    end

    # Load the configuration from a file
    # @param snoopies_json [String] json string
    def load_json(snoopies_json)
      load_array JSON.parse(snoopies_json)
    end

    # Load the configuration from a file
    # @param snoopies_array [Array]
    def load_array(snoopies_array)
      snoopies_array.each do |s|
        @snoopies << Snoopy.new(s)
      end
      raise ArgumentError.new 'There are no Snoopies in the JSON Snooper ' if @snoopies.size == 0
    end

    # Use the snoopies and start snooping
    def snoop
      @snoopies.each do |snoopy|
        if (!snoopy.dir.nil?) && (snoopy.dir?)
          snoop_dir snoopy
        else
          snoop_file snoopy
        end
      end
      get_tracked
    end

    def snoop_dir(snoopy)
      Snoopit.logger.debug "Snooping directory: #{snoopy.dir}"
      get_files(snoopy).each do |file|
        next if File.directory? file
        sniff_it snoopy, "#{snoopy.dir}/#{file}"
      end
    end

    def get_files(snoopy)
      if snoopy.glob?
        files = get_glob_list snoopy
      else
        files = get_file_list snoopy
      end
      files
    end

    def get_glob_list(snoopy)
      Snoopit.logger.debug "Snooping glob: #{snoopy.glob}"
      cwd = Dir.getwd()
      begin
        Dir.chdir snoopy.dir
        files = Dir.glob snoopy.glob
      ensure
        Dir.chdir cwd
      end
      files
    end

    def get_file_list(snoopy)
      Snoopit.logger.debug "Snooper directory: #{snoopy.dir}"
      Dir.entries snoopy.dir
    end

    def snoop_file(snoopy)
      raise ArgumentError.new "Could find file #{snoopy.input}" unless File.exist? snoopy.input
      Snoopit.logger.debug "Snooping file: #{snoopy.input}"
      sniff_it snoopy, snoopy.input
    end

    def sniff_it(snoopy, file_name)
      Snoopit.logger.debug "Sniffing file: #{file_name}"
      line_no = 1
      File.foreach file_name do |line|
        snoopy.sniff snoopy.input, line_no, line
        line_no += 1
      end
    end

    def get_tracked
      tracked = []
      @snoopies.each do |snoopy|
        tracked << snoopy.get_tracked
      end
    end

  end

end
