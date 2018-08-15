#!/usr/bin/env ruby

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "\nUsage: obfus [options] <file [file ...]>"

  opts.on('-v', '--[no-]verbose', 'Run verbosely') { |v| options[:verbose] = v }
  opts.on('-a', '--all', 'Compress all') { |v| options[:all] = v }

end.parse!

# puts options
# puts ARGV

