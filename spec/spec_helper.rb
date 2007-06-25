unless Object.const_defined? :LLIP
  $:.unshift(File.join(File.dirname(__FILE__), "/../lib/llip"))

  require File.join(File.dirname(__FILE__), "/../lib/llip")

  include LLIP

  require 'rubygems'
  require 'spec'

  $: << File.dirname(__FILE__) + "/../examples/ariteval"
end