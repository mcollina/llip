#! /usr/bin/ruby

unless Object.const_defined? :LLIP
  require File.join(File.dirname(__FILE__), "/../../lib/llip")
end

require File.dirname(__FILE__) + "/ariteval"

Signal.trap("INT") do
  puts "Goodbye!"
  exit(0)
end
  
parser = Ariteval.new
  
loop do
  print "> "
  string = readline.strip
  begin
    puts "=> " + parser.evaluate(string).to_s
  rescue Exception => er
    puts "Exception raised: \"#{er.message}\""
  end
end
