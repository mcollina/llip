require File.dirname(__FILE__) + '/regexp_specification'
require File.dirname(__FILE__) + '/abstract_scanner'
require File.dirname(__FILE__) + '/llip_error'

module LLIP
  
  # The RegexpAbstractScanner is the main abstract scanner of LLIP. 
  # To have a real scanner, just subclass it and add some regular expressions. 
  #
  # See ClassMethods to know how.
  class RegexpAbstractScanner < AbstractScanner
    
    def self.inherited(other)
      other.extend(ClassMethods)
    end
    
    def initialize(*args)
      super
      self.class.build unless self.class.built?
    end
    
    def next
      return @current = Token.new(:nil,nil,@current_line,@current_char) unless @next_char
      
      line = @current_line
      char = @current_char
      
      regexp = self.class.scanning_table[@next_char]
      unless regexp
        token = Token.new(:nil,@next_char,line,char)
        raise LLIPError.new(token,"there isn't a regular expression which starts with #{@next_char}")
      end
      
      state = regexp.init
      string = ""
      while state[@next_char] != :error and @next_char
        state = state[@next_char]
        string << @next_char
        read_next
      end
      
      token = Token.new(state.regexp.name,string,line,char)
      if state.final?
        @current = token
      else
        raise UnvalidTokenError.new(token)
      end
    end
    
    module ClassMethods
      
      # Its where all the regular expressions are stored. The keys are the starting_chars of the RegexpSpecification. 
      # While the table can be modified directly, it's reccomanded to use the add_regexp method.
      def scanning_table
        @scanning_table ||= Hash.new 
      end
      
      # It allows to add a RegularExpression to the scanner and it makes sure that all the specified tokens don't collide.
      #
      # If a RegexpSpecification has starting_chars == :everything, it's set to the default value of the scanning_table. 
      def add_regexp(regexp)
        starting_chars = regexp.starting_chars
        if starting_chars.kind_of? Symbol 
          scanning_table.default = regexp
        else
          common_chars = starting_chars.select { |c| scanning_table.has_key? c } 
          starting_chars = starting_chars - common_chars
          starting_chars.each { |c| scanning_table[c] = regexp }
          colliding_states = common_chars.map { |c| scanning_table[c] }
          colliding_states.uniq!
          colliding_states.zip(common_chars).each { |r,c| scanning_table[c] = RegexpSpecification.mix(regexp,r) }
        end	
        
        if @built
          build
        end
        
        self
      end
      
      # It fix a problem with all the regexp that ends with ".*" or ".+". 
      # If such a regexp is given without calling this method, 
      # all the successive chars are going to be included by that regexp.
      # This method add :error in the last state of that regexp for all 
      # starting chars in the scanner.
      #
      # This method is automatically called when a new scanner is istantiated.
      def build
        regexps = scanning_table.values.uniq
        regexps << scanning_table.default if scanning_table.default
        
        fixable = []
        regexps.each do |regexp|
          regexp.last.each do |state|
            fixable << state if state.error == state
          end
        end
        
        starting_chars = scanning_table.keys
        fixable.each do |state|
          starting_chars.each do |char|
            state[char] = :error
          end
        end
        @built = true
        self
      end
      
      # It returns true if the build method has been called.
      def built?
        @built = false if @built.nil?
        @built
      end
    end
  end
end
