require 'forwardable'

module LLIP
  # This class represents a specification for a Regexp as an Hash of State because of the equivalence between finite state machines and regular expressions.
  class RegexpSpecification
    
    extend Forwardable
    
    def_delegators :@init, :[], :[]=, :keys, :values, :each, :error, :error=, :final?, :final=, :regexp, :regexp=
    
    # The name of the RegexpSpecification. Its default is nil
    attr_accessor :name
    
    # The first value inserted in the RegexpSpecification
    attr_reader :init
    
    # It's an hash containing all the states that compose this RegexpSpecification
    attr_reader :states
    
    # The +name+ is stored in the attribute name.
    def initialize(name=nil)
      @states = Hash.new { |hash,key| raise "Unknown RegexpSpecification::State #{key}" }
      @name = name.to_sym if name
    end
    
    # :call-seq:
    # 	add_state(RegexpSpecification::State) => RegexpSpecification::State
    #		add_state({}) => RegexpSpecification::State
    #		add_state => RegexpSpecification::State
    #
    # Adds a State to the RegexpSpecification with the name as a key. 
    # If an hash is passed, it will create a State with that hash as a parameter. 
    # If nothing is passed, an empty Hash is taken as the default.
    def add_state(arg={})
      unless arg.kind_of? State or arg.kind_of? RegexpSpecification
        arg = State.new(arg)
      end
      @init ||= arg
      arg.regexp = self
      @states[arg.name]=arg
    end
    
    # Returns :everything if the init State has an error which is not a State. Returns the init State keys otherwise.
    def starting_chars
      if self.init
        if self.init.error.kind_of? State
          :everything
        else
          self.init.keys
        end
      else
        []
      end	
    end
    
    # Calls init.last
    # 
    # See State#last	
    def last
      return [] unless @init
      @init.last
    end
    
    public
    class State < Hash
      
      # It's a Numeric and it globally identifies a State.	
      attr_reader :name
      
      # see State#final?
      attr_writer :final
      
      # The RegexpSpecification of this state
      attr_accessor :regexp
      
      @@next_name = 0
      
      # The defaults are:
      # 	* :final => false
      # 	* :error => :error
      #
      # If :error is set to :self, the error code it's set to the name of the State, i.e. state[:unknown_key] == state.name => true. This is used to have a everything-like behaviour.
      def initialize(hash = {})
        @name = (@@next_name += 1)
        
        if hash[:error] == :self
          super self
        elsif hash[:error].nil?
          super :error
        else
          hash[:error] = hash[:error].to_sym if hash[:error].respond_to? :to_sym
          super hash[:error]
        end
        
        @final = hash[:final] || false
        
        self
      end
      
      # :call-seq:
      # 	final? => true
      # 	final? => false
      #
      # It identifies if a State is final or not.
      def final?
        @final
      end
      
      # As a State is globally identified by it's name so it's valid to use it as the hash code.
      def hash
        @name.hash
      end
      
      alias :error :default
      alias :error= :default=
      
      def ==(other)
        if other.respond_to? :error
          return false unless other.error === error
        end
        super
      end
      
      # Return an Array which contains all the last states reachable starting from this state, those which must be marked as final.
      #
      # It internally calls RegexpSpecification.last_accessor	
      def last
        RegexpSpecification.last_accessor(self).uniq	
      end
      
    end
    
    # :call-seq:
    # 	RegexpSpecification.last_accessor(RegexpSpecification::State) => Array
    #
    # Returns an Array which contains all the last states reachable starting from _state_. The states in the array may be duplicated.
    def self.last_accessor(state,last=[],examined={},prev=nil)
      
      future_states = state.values.uniq
      
      future_states << state.error if ( state.error.kind_of? RegexpSpecification::State or state.error.kind_of? RegexpSpecification ) and state.error != state 
      
      unless examined.has_key? state
        examined[state] = {}
        examined[state][prev] = true	
        
        if future_states.size == 0
          last << state
        else
          future_states.each do |s|
            last_accessor(s,last,examined,state)
          end
        end
      else
        future_state_unvisited = future_states.select { |s| not examined[s] }
        last << state if future_state_unvisited.size == 0 and ( examined[state][prev] or examined[state][state] or prev == state )
        examined[state][prev] = true
      end
      last
    end
    
    # This method is used by RegexpAbstractScanner to mix two different RegexpSpecification which have starting chars in common.
    # It raises an exception if the two regexp have some common chars marked as final.
    def self.mix(first,second)
      regexp = self.new("mix between '#{first.name}' and '#{second.name}'") 
      mix_accessor(first.init,second.init,regexp,regexp.add_state)
      regexp
    end
    
    private
    def self.mix_accessor(first, second, regexp, last,examined={first => last , second => last}) # :nodoc:
      first_keys = first.keys - second.keys
      common_keys = first.keys - first_keys
      second_keys = second.keys - common_keys
      
      accessor = lambda do |new_first,new_second,state|
        examined[new_first] ||= state
        examined[new_second] ||= state
        
        if new_first.final? and new_second.final?
          raise "It's impossible to mix two regexp with final states in common."
        elsif new_first.final?
          state.regexp = new_first.regexp
          state.final = true
        elsif new_second.final?
          state.regexp = new_second.regexp
          state.final = true
        end
        mix_accessor(new_first,new_second,regexp,state,examined)
      end
      
      common_keys.each do |key|
        unless examined.has_key? first[key] and examined.has_key? second[key]
          state = regexp.add_state
          last[key] = state
          accessor.call(first[key],second[key],state)
        else
          last[key] = examined[first[key]] # because examined[first[key]] and examined[second[key]] are the same
        end	
      end
      
      if first.error.kind_of? State and second.error.kind_of? State
        state = regexp.add_state
        last.error = state
        accessor.call(first.error,second.error,state)
      elsif first.error.kind_of? State
        last.error = first.error
      elsif second.error.kind_of? State
        last.error = second.error
      end
      
      first_keys.each  { |key| last[key] = first[key] }
      second_keys.each { |key| last[key] = second[key] }
    end
  end
end
