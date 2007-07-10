require File.dirname(__FILE__) + '/abstract_parser'
require File.dirname(__FILE__) + '/regexp_abstract_scanner'
require File.dirname(__FILE__) + '/regexp_parser'
require File.dirname(__FILE__) + '/regexp_scanner'
require File.dirname(__FILE__) + '/buffer'
require 'forwardable'

module LLIP
  
  # It's a +facade+ of the LLIP library.
  #
  # To use it subclass it and then use the methods: production, scope and token to build the parser and its scanner.
  class Parser
    
    def self.inherited(other)
      other.extend(ClassMethods)
      other.send(:init_parser)
    end
    
    # The parser of the Parser subclass. It's created from the class returned from LLIP::Parser::ClassMethods.parser.
    attr_reader :parser
    
    # The scanner of the Parser subclass. It's created from the class returned from LLIP::Parser::ClassMethods.scanner.
    attr_reader :scanner
    
    def initialize
      @parser = self.class.parser.new
      @scanner = self.class.scanner.new
      @scanner = Buffer.new(@scanner) if self.class.lookahead
    end
    
    # Parse the source using the parser and the scanner.
    #
    # See AbstractScanner#scan to know what is a valid source.
    def parse(source)
      @parser.parse(@scanner.scan(source))
    end
    
    module ClassMethods
      
      # A class descending from AbstractParser which will contain all the productions.
      # The messages :production and :scope are redirected to it.
      # See AbstractParser::ClassMethods#production, AbstractParser::ClassMethods#scope and ProductionSpecification.
      attr_reader :parser
      
      # A class desceding from RegexpAbstractScanner which will contain all the token definitions.
      # To add it in a simple way use token.
      attr_reader :scanner
      
      # It's a RegexpParser
      attr_reader :regexp_parser
      
      # It's a RegexpScanner
      attr_reader :regexp_scanner
      
      extend Forwardable
      
      def_delegators :@parser, :production, :scope
      
      # It use _regexp_parser_ and _regexp_scanner_ to compile a correct regular expression string in a RegexpSpecification.
      # A correct regular expression string must follow the grammar specified in RegexpParser.
      #
      # The first argument is the name with which all the Token derived by this regular expression will be marked. It must be a symbol.
      def token(name,string)
        regexp = @regexp_parser.parse(@regexp_scanner.scan(string))
        regexp.name = name
        @scanner.add_regexp(regexp)
        self
      end
      
      # :call-seq:
      # 	lookahead
      # 	lookahead(true)
      #
      # It allows to set the lookahead behaviour. If the lookahead is set to true, a Buffer will be used during parsing.
      def lookahead(lookahead = nil) 
        @lookahead = lookahead unless lookahead.nil?
        @lookahead
      end
      
      private
      def init_parser # :nodoc:
        @parser = Class.new(AbstractParser)
        @scanner = Class.new(RegexpAbstractScanner)
        
        @regexp_scanner = Buffer.new(RegexpScanner.new)
        @regexp_parser = RegexpParser.new
        
        @lookahead = false
      end
    end
  end
end
