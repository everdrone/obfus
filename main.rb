#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'fileutils'
require 'open3'
require 'yaml'

class Obfus

  VERSION = '0.1.0'.freeze

  CONFIG_LOCATIONS = [
    File.join(ENV['HOME'], '.config', 'obfus', '{.,}config*'),
    File.join(ENV['HOME'], '.config', 'obfus', '.obfus{config*,rc}'),
    File.join(ENV['HOME'], '.obfus{config*,rc}')
  ].freeze

  def self.find_config
    list = []
    CONFIG_LOCATIONS.each do |pattern|
      list += Dir.glob pattern
    end

    if list.count < 1
      # no config file detected
    else
      list[0]
    end
  end

  def self.parse_config(file)
    File.open(file, 'r') do |f|
      parsed = YAML.safe_load f.read
    end
  end

  def self.ensure_file(name)
    path = File.expand_path name
    path if File.exist? path
  end

  def self.archive(files)
    if files.count == 1
      # check if directory, otherwise create it and proceed
      if File.directory? files[0]
        # proceed
      end
    elsif files.count >= 1
      # create directory named 'Archive'
      FileUtils.mkdir 'Archive'
      archive_dir_path = File.expand_path 'Archive'
      # use `mv` if --no-keep, otherwise use `cp`
      FileUtils.mv files, archive_dir_path
      # proceed
    else
      puts 'no files given'
    end
  end

  def self.compress(archive)
    File.open 'Archive.tbrg', 'w' do |f|
      Open3.pipeline_r(
        ['tar', 'cf', '-', archive],
        ['brotli', '-cq', '9'],
        ['gpg', '-er', 'giorgiotropiano@gmail.com']
      ) do |o, ts|
        ts.each { |t| puts t.pid }
        f.write o.read
      end
    end
  end

  def self.decompress(archive)
    `gpg -d #{archive} | brotli -cd | tar -x`
  end

  def self.exec(args)
    options = OpenStruct.new
    options.recipients = []
    options.verbosity = :normal

    # load default preset
    config_file = find_config
    config_file = parse_config(config_file)

    # add condition to check existence of "default" preset
    default = OpenStruct.new config_file['default']

    options.recipients += default.recipients
    options.level = default.level

    opt_parser = OptionParser.new do |opts|
      opts.banner = "\nUsage: obfus [options] <file...>"
      opts.separator ''
      opts.separator 'Operation Modes:'
      opts.on('-z', '--compress', 'Compress operation mode (default)') do |mode|
        options.mode = :compress
      end
      opts.on('-d', '--decompress', 'Decompress operation mode') do |mode|
        options.mode = :decompress
      end

      opts.separator ''
      opts.separator 'Options:'
      opts.on('-p', '--preset NAME', 'Use a configuration preset') do |name|
        options.preset = name
      end
      opts.on('-l', '--level [0..9]', Integer, 'Specify compression level (defaults to 9)') do |level|
        options.level = level
      end
      opts.on('-k', '--[no-]keep', 'Keep the original files') do |keep|
        options.keep = keep
      end
      opts.on('-r', '--recipients x,y,z', Array, 'Add recipients list') do |list|
        options.recipients += list
      end

      opts.on('-v', '--[no-]verbose', 'Run verbosely') do |verbose|
        options.verbosity = :verbose
      end
      opts.on('-q', '--quiet', 'Suppress any output') do |quiet|
        options.verbosity = :quiet
      end

      opts.separator ''
      opts.separator 'Other options:'
      opts.on_tail('--version', 'Show the version number') do
        puts ::VERSION
        exit
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)

    puts options
    puts ARGV
  end # exec()

end # class Obfus

Obfus.exec(ARGV)
