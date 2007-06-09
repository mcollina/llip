require 'rubygems'
require 'spec'

$:.unshift(File.join(File.dirname(__FILE__), "/../lib/llip"))

require 'llip'

include LLIP

$: << File.dirname(__FILE__) + "/../examples/ariteval"
