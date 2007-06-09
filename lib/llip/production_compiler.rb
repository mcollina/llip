
module LLIP

  # It's the main class which handles the generation of the source code dinamically.
  class ProductionCompiler
    
    # It contains the produced
    attr_reader :code
    
    def initialize
      reset
    end
    
    # It initializes the compiler for a new generation.
    def start(name)
      reset
      @name_str = name
      @name = str_to_sym(name)
      @code << <<-CODE
			def parse_#{name}
				result = productions[#{@name}].default.call(@scanner,self)
		CODE
      self
    end
    
    # :call-seq:
    # 	token(Array)
    # 	token(Symbol)
    # 	token(String)
    #
    # If the argument is a Symbol or a String, the produced code will match them through ==.
    # It the argument is an Array, lookaheads will be used, so the scanner must support lookaheads (or use a Buffer which supports them).
    def token(tokens)
      lookaheads = ""
      name = nil
      token_identifier = nil
      
      if tokens.kind_of? Array
        tokens_names = tokens.map { |tk| build_token_name(tk) }
        token_identifier = "["
        tokens_names.each { |tk| token_identifier << tk + "," }
        token_identifier[-1] = "]"	
        
        name = build_token_name(tokens[0])
        counter = 0
        tokens[1..-1].each do |token|
          lookaheads << " and " 
          counter += 1
          token = build_token_name(token)
          lookaheads << "@scanner.lookahead(#{counter}) == #{token}"
        end
      else
        name = build_token_name(tokens)
        token_identifier = name
      end
      
      @code << <<-CODE
			#{@else}if @scanner.current == #{name}#{lookaheads}
				result = productions[#{@name}].tokens[#{token_identifier}].call(result,@scanner,self)
		CODE
      @else = "els"
      self
    end
    
    # It closes the method definition
    def end(raise_on_error=true)
    build_else(raise_on_error) if @else != ""
    build_end
  end
    
  # It resets the compiler
  def reset
    @code = ""
    @name = nil
    @else = ""
  end
    
  # It takes a ProductionSpecification and then call its compiling methods by itself. It takes care to order all the productions the right way.
  def compile(production)
    start(production.name)
    sort_production(production).each { |tk| token(tk)}
    self.end(production.raise_on_error)
  end
    
  def sort_production(production) # :nodoc:
    tokens = production.tokens
      
    lk_tk = []
    not_lk_tk = []
      
    tokens.keys.each	do |tk|
      if tk.kind_of? Array
        lk_tk << tk
        lk_tk << tk[0] if tokens.has_key? tk[0]
      end
    end	
      
    not_lk_tk = tokens.keys - lk_tk
      
    lk_tk.uniq!	
    lk_tk.sort! do |a,b|
      if a.kind_of? Array and b.kind_of? Array
        if a.size > b.size
          -1
        else
          1
        end
      elsif a.kind_of? Array and not b.kind_of? Array
        -1
      else
        1
      end
    end
     	
    if not_lk_tk.include? :everything
      ret_value = not_lk_tk + lk_tk
      ret_value.delete(:everything)
      ret_value << :everything
      ret_value
    else
      not_lk_tk + lk_tk
    end
  end
    
  protected
  # :call-seq:
  # 	str_to_sym(object) => ":#{object.to_s}"
  #
  def str_to_sym(string)
    string = string.to_s
    ":\"#{string}\""
  end
    
  # :call-seq:
  # 	build_token_name(string) => "'#{string}'"
  # 	build_token_name(symbol) => ":#{object.to_s}"
  #
  def build_token_name(string)
    if string.kind_of? String
      "'#{string.gsub("\\","\\\\\\")}'"
    elsif string.kind_of? Symbol
      str_to_sym(string)
    end
  end
    
  # It builds the else clause in the method definition.
  # It accepts a raise_on_error parameter to specify if it has to raise or not.
  def build_else(raise_on_error=true)
    if raise_on_error
      @code << <<-CODE
				else
					raise NotAllowedTokenError.new(@scanner.current,#{@name})
			CODE
    end
    @code << "\nend\n"
    @else = ""
  end
    
  # It closes the method definition and sets the return value
  def build_end
    @code << <<-CODE
	 			return result
			end	
		CODE
  end
    
end
end
