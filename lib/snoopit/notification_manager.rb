module Snoopit

  class NotificationManager

    attr :active, :config

    def initialize(config=nil)
      @active = {}
      @config = config
      load_default_notifiers unless @config.nil?
    end

    def load_notifier_config(config)
      @config = config
      load_default_notifiers unless @config.nil?
    end

    def register(notifier)
      raise NameError.new "Notifier missing valid name: #{notifier.inspect}" if notifier.name.nil?
      Snoopit.logger.info "Registering notifier #{notifier.name}"
      @active[notifier.name] = notifier
    end

    def unregister(notifier)
      self.unregister_by_name notifier.name
    end

    def unregister_by_name(notifier_name)
      @active.delete notifier_name
    end

    def get_notifier(name)
      @active[name]
    end

    def notify(snoopies)
      snoopies.each do |snoopy|
        snoopy.sniffers.each do |sniffer|
          sniffer_notify(sniffer)
        end
      end
    end

    def sniffer_notify(sniffer)
      messages = get_sniffed_messages sniffer
      sniffer.notifiers.each do |notifier|
        unless notifier.nil?
          notifier.keys.each do |key|
            n = @active[key]
            next if n.nil?
            messages.each do |message|
              n.notify(message, notifier)
            end
          end
        end
      end
    end

    private

    def create_default_notifiers
      Snoopit::Notifiers.constants.select do  |c|
        if Class === Snoopit::Notifiers.const_get(c)
          o = Snoopit::Notifiers.const_get(c).new
          @active[o.name] = o
          o.set_config @config[o.name] unless @config.nil? || @config[o.name].nil?
        end
      end
    end

    def load_default_notifiers
      path = File.expand_path('../notifiers', __FILE__)
      Dir.entries(path).each do |file|
        next if File.directory? file
        file_require "#{path}/#{file}"
      end
      create_default_notifiers
    end

    def file_require(file)
      require file
    end

    def get_sniffed_messages(sniffer)
      messages = []
      sniffer.sniffed.each do |sniffed|
        messages << build_message(sniffed)
      end
      messages
    end

    def build_message(sniffed)
      {
          comment: sniffed.comment,
          file: sniffed.file,
          before: sniffed.before.register.reverse,
          match: sniffed.match,
          match_line_no: sniffed.line_no,
          after: sniffed.after.register.reverse
      }
    end

  end

end