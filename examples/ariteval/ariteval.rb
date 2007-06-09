require 'parser'
require 'evaluator'

class Ariteval < Parser
	
	def initialize
		super
		@evaluator = Evaluator.new
	end

	def evaluate(source)
		parse(source).accept(@evaluator)
		@evaluator.result
	end

	# tokens definitions
	
	numbers = ("0".."9").to_a.join("|")
	token :number, "(#{numbers})+ *"

	token :plus, '\+ *'
	
	token :minus, '- *'
	
	token :mul, '\* *'
	
	token :div, '/ *'

	token :"(", '\( *'
	
	token :")", '\) *'

 	identifiers = (("a".."z").to_a + ("A".."Z").to_a).join("|")
	token :ident, "(#{identifiers}) *"

	token :assign, "= *" 
	
	# production definitions
	
	lookahead(true)
	
	scope :exp

	production(:exp,:recursive) do |prod|
		prod.default { |scanner,parser| parser.parse_term }

		prod.token(:plus) do |term_seq,scanner,parser|
			scanner.next
			next_term = parser.parse_term
			PlusExp.new(term_seq,next_term)
		end	

		prod.token(:minus) do |term_seq,scanner,parser|
			scanner.next
			next_term = parser.parse_term
			MinusExp.new(term_seq,next_term)
		end
	
	end

	production(:term,:recursive) do |prod|
		prod.default { |scanner,parser| parser.parse_factor }

		prod.token(:mul) do |factor_seq,scanner,parser|
			scanner.next
			next_factor = parser.parse_factor
			MulExp.new(factor_seq,next_factor)
		end	

		prod.token(:div) do |factor_seq,scanner,parser|
			scanner.next
			next_factor = parser.parse_factor
			DivExp.new(factor_seq,next_factor)
		end	
	end

	production(:factor,:single) do |prod|
		
		prod.token(:number) do |result,scanner|
			current = scanner.current
			scanner.next
			NumExp.new(current.value.to_i)
		end

		prod.token(:"(") do |result,scanner,parser|
			scanner.next
			result = parser.parse_exp
			parser.raise "Every '(' must be followed by a ')'" unless scanner.current == :")"
			scanner.next
			result
		end

		prod.token(:ident,:assign) do |result,scanner,parser|
			name = scanner.current.to_s.strip
			scanner.next
			scanner.next
			AssignIdentExp.new(name,parser.parse_exp)
		end

		prod.token(:ident) do |result,scanner,parser|
			result = IdentExp.new(scanner.current.to_s.strip)
			scanner.next
			result
		end

	end

end
