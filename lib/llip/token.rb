module LLIP
  class Token
    
    # The name of the Regexp that generated this token
    attr_reader :name
    
    # The matched String
    attr_reader :value
    
    # The line at which this token was matched
    attr_reader :line
    
    # The position of the first char in the token
    attr_reader :char
    
    alias :to_s :value
    alias :to_str :value
    
    def initialize(name=:nil,value=nil,line=-1,char = -1)
      @name = name
      @value = value
      @line = line
      @char = char
    end
    
    def nil?
      value.nil?
    end
    
    def ==(other)
      if other.respond_to? :name
        other.name == @name
      elsif other.respond_to? :to_str
        @value == other.to_str
      elsif other.respond_to? :to_sym	
        return true if other == :everything
        other.to_sym == @name
      else
        nil
      end
    end
    
    def =~(regexp)
      @value =~ regexp
    end
  end
end
