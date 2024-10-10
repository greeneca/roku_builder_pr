# ********** Copyright Viacom, Inc. Apache 2.0 **********

module RokuBuilder

  class PR < Util
    extend Plugin

    # Hash of commands
    # Each command efines a hash with three optional values
    # Setting device to true will require that there is an avaiable device
    # Setting source to true will require that the user passes a source option
    #   with the command
    # Setting stage to true will require that the user passes a stage option
    #   with the command
    def self.commands
      {
        pr: {},
      }
    end

    # Hook to add options to the parser
    # The keys set in options for commands must match the keys in the commands
    #   hash
    def self.parse_options(parser:,  options:)
      parser.separator "Commands:"
      parser.on("--pr", "Create PR") do
      end
    end

    # Array of plugins the this plugin depends on
    def self.dependencies
      [Linker]
    end

    def init
      #Setup
    end

    # Sample command
    # Method name must match the key in the commands hash
    def pr(options:)
    end

    def read_config()
      config = nil
      File.open(config_path) do |io|
        config = JSON.parse(io.read, {symbolize_names: true})
      end
      config
    end
    def write_config(config)
      File.open(config_path, "w") do |io|
        io.write(JSON.pretty_generate(config))
      end
    end
    def config_path()
      file = File.join(@config.project[:directory], ".roku_builder_pr.json")
      unless File.exist?(file)
        @logger.fatal "Missing Config File"
        exit
      end
      return file
    end
  end

  # Register your plugin
  RokuBuilder.register_plugin(PR)
end
