require File.dirname(__FILE__) + '/abstract_parser'

module LLIP
	
  # It's a parser for regular expression. It correctly builds a RegexpSpecification given a valid regular expression string.
  #
  # === Grammar
  #	
  # VN = { EXP , ELEMENT}
  #
  # char = every charachter
  #	
  # symb = { ( , ) , . , * , + , \ , |}
  #	
  # VT = char U symb
  #
  # In every production it has been used "or" instead of "|" to not make confusion.
  #
  # P = {
  #   EXP -> META EXP
  #   EXP -> META or EXP
  #   EXP -> META
  #   META -> ELEMENT*
  #   META -> ELEMENT+
  #   META -> ELEMENT
  #   ELEMENT -> char or . or \symb
  #   ELEMENT -> (EXP)
  # }
  #
  # or in EBNF format
  #
  # P' = {
  #   EXP ::= META{[|]EXP}
  #   META ::= ELEMENT[* or  +]
  #   ELEMENT ::= char or . or \symb or (EXP)
  # }
  #
  class LLIP::RegexpParser < LLIP::AbstractParser
    
    SPECIALS_TABLE = {
      "n" => "\n",
      "r" => "\r",
      "t" => "\t"
    }
    
    SPECIALS_TABLE.default = lambda { |hash,key| raise 'Unknown special #{key}' }
    
    scope(:scope)
    
    production(:scope,:single) do |p|
      p.default do |scanner,parser|
        parser[:regexp] = RegexpSpecification.new
        parser[:last] = [parser[:regexp].add_state]
        
        parser.parse_exp
        
        parser[:regexp].last.each { |s| s.final= true }
        parser[:last].each { |s| s.final = true }
        parser[:regexp]
      end
    end
    
    production(:exp,:recursive) do |p|
      
      p.default do |scanner,parser|
        parser.parse_meta.last
      end
      
      p.token("|") do |result,scanner,parser|
        result 
        scanner.next
        parser[:last] = result
        parser.parse_meta.last
      end
      
      p.token(:char) do |result,scanner,parser|
        parser.parse_meta
        result
      end
      
      p.token(".") do |result,scanner,parser|
        parser.parse_meta
        result
      end
      
      p.token("(") do |result,scanner,parser|
        parser.parse_meta
        result
      end
      
      p.token("\\") do |result,scanner,parser|
        parser.parse_meta
        result
      end
    end
    
    production(:meta,:single) do |p|
      p.raise_on_error = false
      
      p.default do |scanner,parser|
        MetaAccessor.new(parser[:last],parser.parse_element)
      end
      
      p.token("*") do |meta,scanner,parser|
        if meta.results == :everything
          parser[:last].last.error = parser[:last].last
        else
          if meta.results.kind_of? Array
            meta.results.each do |c|
              parser[:last].each { |s| s[c] = meta.last.last[c] }						
            end	
          else
            parser[:last].last[meta.results] = parser[:last].last
          end
          parser[:last].concat(meta.last)
        end
        scanner.next
        meta
      end
      
      p.token("+") do |meta,scanner,parser|
        if meta.results == :everything
          parser[:last].last.error = parser[:last].last
          parser[:last] = [parser[:last].last]
        else
          if meta.results.kind_of? Array
            meta.results.each do |c|
              parser[:last].each { |s| s[c] = meta.last.last[c] }						
            end	
          else
            parser[:last].last[meta.results] = parser[:last].last
          end		
        end
        scanner.next
        meta
      end
    end
    
    production(:element,:single) do |p|
      
      p.token(:char) do |result, scanner, parser|
        parser.add_char(parser,scanner)
      end
      
      p.token(".") do |result, scanner, parser|
        r = parser[:regexp].add_state
        parser[:last].last.error = r
        parser[:last] << r
        scanner.next
        :everything	
      end
      
      p.token("\\") do |result,scanner,parser|
        if scanner.next == :symbol
          parser.add_char(parser,scanner)
        else
          parser.add_char(parser,scanner,SPECIALS_TABLE[scanner.current.value])
        end	
      end
      
      p.token("(") do |result,scanner,parser|
        scanner.next
        first_state = parser[:last].last
        parser.parse_exp
        
        unless scanner.current == ")"
          raise "Every '(' must be followed by a ')'"
        end
        
        scanner.next
        parser[:last] = first_state.last
        first_state.keys
      end
    end
    
    def add_char(parser, scanner, char=scanner.current.value)
      r = parser[:regexp].add_state
      parser[:last].each { |s| s[char] = r }
      parser[:regexp].add_state(r)
      parser[:last] = [r]
      scanner.next
      char
    end
    
    class MetaAccessor
      
      attr_accessor :results
      attr_accessor :last
      
      def initialize(last,results)
        @results = results
        @last = last
      end
      
    end
  end
end
