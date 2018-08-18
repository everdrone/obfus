require 'optparse'
require 'ostruct'
require 'fileutils'
require 'open3'
require 'yaml'

module Obfus
  class Main
    VERSION = '0.1.1'.freeze

    CONFIG_LOCATIONS = [
      File.join(ENV['HOME'], '.config', 'obfus', '{.,}config*'),
      File.join(ENV['HOME'], '.config', 'obfus', '.obfus{config*,rc}'),
      File.join(ENV['HOME'], '.obfus{config*,rc}')
    ].freeze

    OPTIONS = {
      mode: :compress,
      preset: nil,
      level: 9,
      keep: true,
      recipients: [],
      verbosity: :normal
    }.freeze

    class << self
      def find_config
        list = []
        CONFIG_LOCATIONS.each do |pattern|
          list += Dir.glob pattern
        end

        if list.count < 1
          # no config file detected
          nil
        elsif list.count > 1
          # TODO: print warning (multiple config files: <list...>, reading from <path>)
          puts 'error: encountered multiple configuration files:'
          list.each do |l|
            puts File.expand_path l
          end
          puts "reading from: #{File.expand_path list[0]}"
          nil
        else
          list[0]
        end
      end

      def parse_config(file)
        parsed = nil
        File.open(file, 'r') do |f|
          parsed = YAML.safe_load f.read
        end
        parsed
      end

      def apply_config(options)
        file = find_config
        opts = OpenStruct.new OPTIONS
        config = nil
        unless file.nil?
          config = parse_config(file)
          if options.preset.nil?
            if config['default'].nil?
              # use native defaults
            else
              # use config file
              opts = OpenStruct.new config['default']
              opts.preset = 'default'
            end
          else
            # use preset
            opts = OpenStruct.new config[options.preset]
          end
        end

        # override
        options.each_pair do |k, v|
          opts[k] = v
        end

        opts['keep'] = true if opts['keep'].nil?

        opts['config'] = file

        opts
      end

      def ensure_file(name)
        path = File.expand_path name
        File.exist? path
      end

      def compress(files, options)
        archive_name = 'Archive'
        if files.count < 1
          puts 'error: no files specified'
          puts 'try `obfus --help`'
          exit 1
        elsif files.count == 1
          # call it the name of the file
          archive_name = File.basename files[0], '.*'
        end

        unless options.output.nil?
          archive_name = options.output.strip
          archive_name.gsub!(/^.*(\\|\/)/, '')
        end

        unless options.force
          if ensure_file(archive_name)
            # file already exists
            puts "error: file #{archive_name} already exists"
            puts 'to overwrite the file use `--force`'
            exit 1
          end
        end

        files.each do |file|
          next if ensure_file(file)
          # TODO: file <file> does not exist!
          puts "error: #{file} does not exist"
          exit 1
        end

        if options.recipients.count < 1
          # TODO: throw error! no recipients specified
          puts 'error: no recipients specified'
          puts 'try `obfus --help`'
          exit 1
        end

        if options.verbosity == :verbose
          unless options.verbosity == :quiet
            puts 'using config file: ' + options.config
            puts 'using preset: ' + options.preset
            puts 'keeping original files: ' + options.keep.to_s
            puts 'compression quality: ' + options.level.to_s
            puts 'compressing:'
            files.each { |f| puts '- ' + f }
            puts
            puts 'recipients:'
            options.recipients.each { |r| puts '- ' + r }
            puts
          end
        end

        File.open archive_name, 'w' do |f|
          # add recipients `-r <recipient>`
          recipients = []

          options.recipients.each do |r|
            recipients << '-r'
            recipients << r
          end

          Open3.pipeline_r(
            ['tar', 'cf', '-', *files],
            ['brotli', '-cq', options.level.to_s],
            ['gpg', '-eq', *recipients]
          ) do |o, _ts|
            # ts.each { |t| puts t.pid, t.status }
            f.write o.read
          end
        end
      end

      def decompress(file)
        # TODO: iterate over files
        unless ensure_file(file)
          puts "error: file #{file} does not exist"
          exit 1
        end

        Open3.pipeline_r(
          ['gpg', '-dq', file],
          ['brotli', '-dc'],
          ['tar', '-x']
        ) do |o, ts|
          # ts.each { |t| puts t.pid, t.status }
        end
      end

      def exec(args)
        options = OpenStruct.new

        opt_parser = OptionParser.new do |opts|
          opts.banner = "\nUsage: obfus [options] <file...>"
          opts.separator ''
          opts.separator 'Operation Modes:'
          opts.on('-z', '--compress', 'Compress operation mode (default)') do
            options.mode = :compress
          end
          opts.on('-d', '--decompress', 'Decompress operation mode') do
            options.mode = :decompress
          end

          opts.separator ''
          opts.separator 'Options:'
          opts.on('-o', '--output NAME', 'Specify the output file name') do |name|
            options.output = name
          end
          opts.on('-f', '--force', 'Overwrites output file if conflicts with an existing one') do |v|
            options.force = v
          end
          opts.on('-p', '--preset NAME', 'Use a configuration preset') do |name|
            options.preset = name
          end
          opts.on('-l', '--level [0..9]', Integer, 'Specify compression level (defaults to 9)') do |v|
            options.level = v
          end
          opts.on('-k', '--[no-]keep', 'Keep the original files') do |keep|
            options.keep = keep
          end
          opts.on('-r', '--recipients x,y,z', Array, 'Add recipients list') do |list|
            options.recipients = [] if options.recipient.nil?
            options.recipients += list
          end

          opts.on('-v', '--verbose', 'Run verbosely') do
            options.verbosity = :verbose
          end
          opts.on('-q', '--quiet', 'Suppress any output') do
            options.verbosity = :quiet
          end

          opts.separator ''
          opts.separator 'Other options:'
          opts.on_tail('--version', 'Show the version number') do
            puts "obfus@#{VERSION}"
            exit
          end

          opts.on_tail('-h', '--help', 'Show this message') do
            puts opts
            exit
          end
        end

        opt_parser.parse!(args)

        options = apply_config(options)

        if options.mode == :decompress
          # decompress archive
          decompress(ARGV[0])
        else
          # compress
          compress(ARGV, options)
        end

        # puts options
        # puts ARGV
      end # exec()
    end # class << self
  end # class Main
end # module Obfus

# Obfus.exec(ARGV)
