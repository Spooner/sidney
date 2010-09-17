#!/usr/bin/env ruby

begin
  ROOT_PATH = File.dirname(File.expand_path(ENV['OCRA_EXECUTABLE'] || File.dirname(__FILE__)))
  $LOAD_PATH.unshift File.join(ROOT_PATH, 'lib', 'sidney')
  
  LOG_PATH = File.join(ROOT_PATH, 'logs')
  
  # Prevent warnings going to STDERR/STDOUT from killing the rubyw app.
  Dir.mkdir(LOG_PATH) unless File.exists? LOG_PATH

  original_stderr = $stderr.dup
  $stderr.reopen File.join(LOG_PATH, 'stderr.log')
  $stderr.sync = true

  original_stdout = $stdout.dup
  $stdout.reopen File.join(LOG_PATH, 'stdout.log')
  $stdout.sync = true

  require 'game'

rescue Exception => ex
  $stderr.puts "FATAL ERROR - #{ex.class}: #{ex}\n#{ex.backtrace.join("\n")}"
  raise ex # Just to make sure that the user sees the error in the CLI/IDE too.
ensure
  $stderr.reopen(original_stderr) if defined? original_stderr
  $stdout.reopen(original_stdout) if defined? original_stdout
end