require 'jira-ruby'
require 'cli/ui'
require 'git'

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
        branch: {}
      }
    end

    # Hook to add options to the parser
    # The keys set in options for commands must match the keys in the commands
    #   hash
    def self.parse_options(parser:,  options:)
      parser.separator "Commands:"
      parser.on("--pr", "Create PR") do
        options[:stage] ||= "core"
        options[:pr] = true
      end
      parser.on("--create-branch KEY", "Create a git branch following the configured pattern") do |key|
        options[:stage] ||= "core"
        options[:branch] = key
      end
    end

    # Array of plugins the this plugin depends on
    def self.dependencies
      [Linker]
    end

    def init
      #Setup
    end

    # creates a PR using the configured options and user input
    def pr(options:)
      @options = options
    end

    #creates a branch using JIRA information and configured pattern
    def branch(options:)
      @options = options
      @pr_config = read_config
      setup_jira_client
      issue = @client.Issue.find(@options[:branch])
      unless issue
        @logger.fatal "Cannot Find Ticket"
        exit
      end
      title = issue.summary.downcase.gsub(" ", "-").gsub(/[^a-z_-]/, "")
      key = @options[:branch]
      type = get_branch_type(issue.issuetype.name.downcase)
      branch  = @pr_config[:branch][:pattern]
      branch.gsub!("{title}", title)
      branch.gsub!("{key}", key)
      branch.gsub!("{type}", type)
      g = Git.open(@config.project[:directory], :log => @logger)
      g.branch(branch)
      g.branch(branch).checkout
      @logger.unknown "Branch created/checked out: #{branch}"
    end

    private 

    def setup_jira_client
      Warning.ignore(//, //)
      jira_options = @pr_config[:jira][:options]
      jira_options[:auth_type] = jira_options[:auth_type].to_sym
      jira_options.merge!(load_jira_credentials)

      @client = JIRA::Client.new(jira_options)
      @client.Field.map_fields
    end
    def load_jira_credentials
      file = File.join(@config.project[:directory], ".jira_credentials.json")
      if @options[:jira_credentials_path]
        file = @options[:jira_credentials_path]
      end
      credentials = load_config_file(file: file)
      if credentials[:api_token]
        credentials[:default_headers] = { 'Authorization' => "Bearer #{credentials[:api_token]}" }
        credentials.delete(:api_token)
      end
      return credentials
    end
    def read_config()
      load_config_file(file: config_path)
    end
    def config_path()
      file = File.join(@config.project[:directory], ".roku_builder_pr.json")
      unless File.exist?(file)
        @logger.fatal "Missing Config File"
        exit
      end
      return file
    end
    def load_config_file(file:)
      if File.exist?(file)
        JSON.parse(File.open(file).read, {symbolize_names: true})
      else
        raise RokuBuilder::InvalidConfig, "Missing config: #{file}"
      end
    end
    def get_branch_type(issue_type)
      types = @pr_config[:branch][:types]
      potential_types = []
      types.each_pair do |type,req|
        if req[:type].include?(issue_type)
          potential_types.push(type)
        end
      end
      if potential_types.count > 1
        CLI::UI::StdoutRouter.enable
        return CLI::UI.ask("What branch type do you want to use?", options: potential_types.map{|s| s.to_s})
      elsif potential_types.count == 1
        return potential_types.first.to_s
      else
        CLI::UI::StdoutRouter.enable
        return CLI::UI.ask("Enter branch type:")
      end
    end
  end

  # Register your plugin
  RokuBuilder.register_plugin(PR)
end
