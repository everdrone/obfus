#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

def ensure_file(name)
  path = File.expand_path name
  if File.exist? path
    path
  else
    nil
  end
end

def archive(files)
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

def compress(archive)
  `tar cf - #{archive} | xz | gpg -er #{config[:username]} > Archive.tar.xz.gpg`
end

def decompress(archive)
  `gpg -d #{archive} | xz -d | tar -x`
end

def main
  options = {}
  OptionParser.new do |opts|
    opts.banner = "\nUsage: obfus [option...] <file...>"

    opts.on('-v', '--[no-]verbose', 'Run verbosely') { |v| options[:verbose] = v }
    opts.on('-k', '--[no-]keep', 'Keep the original files') { |v| options[:keep] = v }

  end.parse!

  # puts options
  # puts ARGV
end

main
