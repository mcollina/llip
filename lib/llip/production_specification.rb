
module LLIP

	
  # A ProductionSpecification contains all it's needed to transform it into live code.
  # This transformation is done by ProductionCompiler or RecursiveProductionCompiler.
  # 
  # The flow of the execution of a production is:
  # 1. The default block is called and it's result is stored in a +result+ var.
  # 2. The current token is matched against every key of the ProductionSpecification#tokens
  #    hash, and if this match is positive the associated block is executed.
  #    The result is stored inside the +result+ var.
  #    If nothing matches and the ProductionSpecification#mode is :single and ProductionSpecification#raise_on_error
  #    is true an exception must be raised. if nothing matches and the ProductionSpecification#mode is 
  #    recursive the production must return the +result+ var.
  # 3. If the ProductionSpecification#mode is :single, the production must return 
  #    the +result+ var. If the ProductionSpecification#mode is :recursive, the step
  # 2  is going to be executed until it recognizes a Token. 
  class ProductionSpecification
    
    NIL_BLOCK = lambda { nil }
    
    # The production name.
    attr_reader :name
    
    # It's an hash which has as keys the token to recognize and as value the block to be executed with it.
    # They are specified through ProductionSpecification#token.
    attr_reader :tokens
    
    # The mode of the production. It can be :single or :recursive (:iterative is just an alias for :recursive).
    attr_reader :mode
    
    # This attribute specifies if the production should raise an exception if the current token hasn't been recognized.
    # It's important only for :single productions.
    attr_accessor :raise_on_error
    
    def initialize(name)
      @name = name
      @tokens = {}
      @mode = :single
      @default = NIL_BLOCK
      @raise_on_error = true
    end
    
    # :call-seq: 
    #   token(*token_name) { |result, scanner, parser| ... }
    #
    # The block specified through this method will be executed when the token with the specified name is matched.
    # If more than a name is given, the parser should automatically use lookahead and match all the tokens.
    # 
    # This name is going to be matched for equality with a Token.
    #
    # The arguments of the block will be filled by:
    # * The +result+ argument contains the result of a previous called block inside this production.
    # * The +scanner+ is an instance of a class descending from AbstractScanner. It's the scanner used by the parser.
    #   It's important to call +next+ on this scanner to make it build the next token.
    # * The +parser+ is an instance of a class descending from AbstractParser. It's the caller of the production.
    #   It's necessary to call other productions.
    def token(*args,&block) # :yields: result,scanner,parser
      args.flatten!
      block = args.pop if args.last.respond_to? :call
      args = args.first if args.size == 1
      @tokens[args] = block || NIL_BLOCK
      self
    end
    
    # :call-seq:
    #   default() { |scanner, parser| ... }
    #
    # The specified block is going to be executed before any token is recognized.
    # The default is NIL_BLOCK.
    def default(block=nil,&b)
      block ||= b
      @default = block if block
      @default
    end
    
    # see ProductionSpecification#mode
    def mode=(value)
      if value == :iterative
        value = :recursive
      end
      @mode = value
    end
    
  end
end
