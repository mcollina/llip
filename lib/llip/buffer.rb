
module LLIP
  class Buffer
    
    attr_accessor :scanner
    attr_reader :current
    
    def initialize(scanner)
      @scanner = scanner
      @current = nil
      @buffer = nil
    end
    
    def scan(text)
      @scanner.scan(text)
      self
    end
    
    def next
      return @current = @scanner.next unless @buffer
      
      @current = @buffer.shift
      @buffer = nil if @buffer.size == 0
      @current
    end
    
    def lookahead(n)
      @buffer ||= []
      while @buffer.size < n	
        @buffer << @scanner.next
      end
      @buffer[n-1]
    end
  end
end
