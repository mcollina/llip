
module LLIP
  
  # It's the base Exception for all the exception of LLIP.
  # It adds a header to all the messages with the line and the char of the token
  # that caused the exception.
  #
  # To subclass it for a class-specific message, pass it to the constructor or
  # override the :message method.
  #
  class LLIPError < StandardError
    
    # The token that caused the exception
    attr_reader :token
    
    def initialize(token,msg=nil)
      super msg
      @token = token
    end
    
    alias :internal_message :to_s
    
    def to_s
      "At line #{token.line} char #{token.char} a #{self.class.name} occurred: #{internal_message}"
    end
  end
  
  class UnvalidTokenError < LLIPError
    
    def initialize(token)
      super token, "the current token '#{token.value}' doesn't match with the regular expression #{token.name}."
    end
  end
  
  class ParserError < LLIPError
  end
  
  class NotAllowedTokenError < ParserError
    def initialize(token,production)
      super token, "the token '#{token.value}' matched by the regexp '#{token.name}' isn't allowed in production #{production}."
    end
  end
end
