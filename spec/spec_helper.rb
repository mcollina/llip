require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__),"/../lib/llip") 

include LLIP

$: << File.dirname(__FILE__) + "/../examples/ariteval"
