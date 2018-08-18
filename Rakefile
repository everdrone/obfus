require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :standalone do
  mkdir_p 'build'
  File.open('build/obfus', 'w') do |f|
    f.puts '#!/usr/bin/env ruby'
    f.puts ''
    f.puts File.read('bin/obfus').split("require 'obfus/main'\n")[1].prepend(File.read('lib/obfus/main.rb'))
  end
  
  sh 'chmod +x build/obfus'
end

desc 'Install standalone script and man page.'
task :install => :standalone do
  prefix = ENV['PREFIX'] || ENV['prefix'] || '/usr/local'

  mkdir_p "#{prefix}/bin"
  ln_s "build/obfus", "#{prefix}/bin/obfus"
end
