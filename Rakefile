require 'bundler/gem_tasks'

task :default => :test

desc 'Run the tests'
task :test do
  sh 'rspec spec'
end

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
task :mklink => :standalone do
  prefix = ENV['PREFIX'] || ENV['prefix'] || '/usr/local'

  mkdir_p "#{prefix}/bin"
  cp 'build/obfus', "#{prefix}/bin/obfus"
end
