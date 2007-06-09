= LLInterpretedParser

The LL(k) Interpreted Parser (llip) is an automated tool to easily create an LL(k) parser and the related scanner without the need of generating anything. 
Everything is done on the fly through a simple DSL.

== A Little comparrison against other tools

Tools like JavaCC, ANTLR, Coco/R and others use an external description file which they compile into the destination code. 
This file it's usually written using a complex product related language. Using Ruby metaprogramming, a parser generator can go one step further.
In fact, the llip gem gives you the possibility to write a parser writing only Ruby code. 

== Don't compile anything

This tool is based on a simple and powerful DSL that can be used to specify:
* some tokens to be recognized in the form of regular expressions, as defined in LLIP::RegexpParser,
* some productions using LLIP::ProductionSpecification,
* some LL(K) related behaviour like lookaheads.

Everything specified is automatically translated into live objects which can be used to do LL(K) parsing.

== The LLIP Library

The LLIP::Parser is a facade of the entire library. In fact it handles all the wiring to make it work. 
It also takes care of generating the right LLIP::TokenSpecification starting from its definition, 
which is a simple string written as defined in LLIP::RegexpParser.

To use this library it's necessary to subclass LLIP:Parser and so it's possible to specify all the needed behaviours.
An instance of that subclass gains the +parse+ method, which parses a string or an IO with the productions previously defined.

== Installation

<code>gem install llip</code>

== History of this gem

This library was originally developed as a project for a course at the engeneering[http://www.ing.unibo.it] faculty of the university of Bologna, Italy.

== A Simple Example

#! /usr/bin/ruby

require 'rubygems'

require 'llip'

class MyParser < LLIP::Parser
  
  token :num, "(1|2|3|4|5|6|7|8|9|0)+" # simple definition of a number
  
  scope :number # definition of the scope, the first production which will be called
  
  production(:number) do |p|
    
    # inside the :number production,
    # we are specifying what to do when we encounter a :num token
    p.token :num do |result,scanner,parser|
      puts "The number is..."
      number = scanner.current.value
      puts number
      scanner.next
      number
    end

  end
end

puts "--->>> Example 1"

parser = MyParser.new

parser.parse("1")

parser.parse("34065")

parser.parse("123456")

puts "--->>> Example 2"

begin
  parser.parse("3+2")
rescue LLIP::LLIPError => error
  puts error
end

class MyParser
  
  token :plus, '\+' # the '\' is required because it escapes the '+', 
                    # which is a token of a regular expressions.
 
  scope :exp

  production :exp, :recursive do |p|
    p.default { |scanner,parser| parser.parse_number }  # this block is exectued before any
                                                        # other block.
    
    p.token :plus do |left,scanner,parser|
      scanner.next
      right = parser.parse_number # we are calling another production!!
      sum = left.to_i + right.to_i
      puts "The sum is #{sum}"
      sum
    end
  end
end

result = parser.parse "3+2+4"

puts "the result is #{result}"

== A more complex example, the Ariteval parser

Bundled with this library there is an example of an Arithmetic Evaluator, 
which evaluates simple expressions like "3-7*(6-2)". In the "examples/ariteval" directory there are:
[<b>exp.rb</b>] contains all the Abstract Syntax Tree node definitions.
[<b>ariteval.rb</b>] contains the productions definitions using LLIP::Parser.
[<b>evaluator.rb</b>] a simple visitor which uses the classes defined in exp.rb.

== Author

This library has been written by Matteo Collina, matteo dot collina at gmail dot com.

== License

(The MIT license)

Copyright (c) 2006-2007 Matteo Collina

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

