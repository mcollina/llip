# :include: README.txt
module LLIP
  VERSION = "0.2.0"
end

$:.unshift(File.dirname(__FILE__) + "/llip/")

require 'parser'
require 'visitable'
