require File.dirname(__FILE__) + '/production_compiler'

module LLIP
  
  #It modifies ProductionCompiler to add support to a recursive behaviour.
  class RecursiveProductionCompiler < ProductionCompiler
    
    def start(name)
      super
      @code << <<-CODE
        while not @scanner.current.nil?
      CODE
    end
    
    protected
    def build_else(raise_on_error=true)
      if raise_on_error
        @code << <<-CODE
          else
            break
	CODE
      end
      @code << "\nend\n"
      @else = ""
    end
    
    def build_end
      @code << <<-CODE
	end
      CODE
      
      super
    end
  end
end
