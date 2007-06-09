require File.dirname(__FILE__) + '/production_specification'
require File.dirname(__FILE__) + '/production_compiler'
require File.dirname(__FILE__) + '/recursive_production_compiler'
require File.dirname(__FILE__) + '/llip_error'

module LLIP
    
  # This class hide all the complexity of generating an building a parser. 
  # Ater subclassing it, it's possible to use all the methods defined in 
  # AbstractParser::ClassMethods to specify the productions.
  class AbstractParser
    
    def self.inherited(other)
      other.extend(ClassMethods)
    end
    
    def initialize
      @hash = {}
    end
    
    def productions
      self.class.productions
    end
    
    # Parse the token generated from the scanner until it reaches the end.
    # See AbstractScanner to know how to develop a scanner.
    def parse(scanner)
      raise "This method hasn't been compiled yet."
    end
    
    def [](key)
      @hash[key]
    end
    
    def []=(key,value)
      @hash[key] = value
    end
    
    # It raises a ParserError instead of a RuntimeError if no exception is given.
    #
    # It's public so it's important to call it from the production definitions, to have the exception set to ParserError.
    def raise(*args) 
      if args.first.respond_to? :exception or not @scanner.respond_to? :current or @scanner.current == nil
        super(*args)
      else
        error = ParserError.new(@scanner.current,args.shift)
        backtrace = args.shift
        backtrace ||= caller(1)
        error.set_backtrace(backtrace)
        super error
      end
    end
    
    module ClassMethods
      
      # Contains the evaluated code, it's useful for debugging.
      attr_reader :code
      
      # :call-seq:
      # 	autocompile(true)
      # 	autocompile(false)
      #
      # Set the autocompile flag true or false. The default is *true*.
      # If this flag is turned on every production is automatically evaulated and converted into code. 
      # Otherwise you can compile it using AbstractParser::ClassMethods#compile.
      def autocompile(autocompile=nil)
        if not autocompile.nil?
          @autocompile = autocompile 
        else
          @autocompile = true if @autocompile.nil?
        end
        init_compile if @autocompile
        @autocompile
      end
      
      # Add a production to the parser, the block must accept an argument which is
      # a new ProductionSpecification. 
      # The ProductionSpecficiation name is set to the first parameter and its mode to the second if exists.
      # A ProductionSpecification is compiled to a method named +parse_name+
      def production(name,mode=nil) # :yields: production_specification
        productions[name.to_sym] ||= LLIP::ProductionSpecification.new(name.to_sym)
        productions[name.to_sym].mode = mode if mode
        yield productions[name.to_sym]
        compile_production(productions[name.to_sym]) if autocompile
        name
      end
      
      # Return an hash containing all the specified productions
      def productions
        @productions ||= {}
      end
      
      # Return/set the scope, which is the first production to be called.
      # The scope is mandatory to generate the parse method.
      def scope(name=nil)
        if name
          raise ArgumentError.new("The scope must be a not empty string") if name == ""
          @scope = name
          compile_scope if autocompile
        end
        @scope
      end
      
      # Compile all the productions and sets the code attribute correctly.
      def compile
        
        init_compile
        
        #first check the scope
        if @scope.nil? or not @productions.has_key? @scope.to_sym
          raise "You must give a legal scope"
        end
        
        compile_scope
        
        #compile and eval all the productions
        @productions.values.each { |prod| compile_production(prod) }
        
        class_eval(@code)
        @compiled = true
      end
      
      # Returns a boolean which specify if the parser has been compiled
      def compiled
        @compiled ||= false
      end
      
      private
      def compile_scope
        scope_code = <<-CODE
				def parse(scanner)
					@scanner = scanner
					@scanner.next
					result = parse_#{@scope}
					raise "The parsing terminating without processing all tokens, the exceeding token is '\#{@scanner.current}'" unless @scanner.current.nil?
					result
				end
			CODE
        
        class_eval(scope_code) if autocompile
        @code << scope_code
      end
      
      def compile_production(prod)
        if prod.mode == :single
          compiler = @single_compiler
        elsif prod.mode == :recursive
          compiler = @recursive_compiler
        else
          raise "Unknow compile mode(#{prod.mode})for production #{prod.name}"
        end
        
        compiler.compile(prod)
        @code << "\n\n"
        @code << compiler.code
        
        class_eval(compiler.code) if autocompile
        compiler.reset
      end
      
      def init_compile
        unless @code
          @code = "" 
          @single_compiler = LLIP::ProductionCompiler.new
          @recursive_compiler = LLIP::RecursiveProductionCompiler.new
        end
      end
    end
  end
end
