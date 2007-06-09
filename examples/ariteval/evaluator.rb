
class Evaluator

	attr_reader :ident_table

	def initialize
		@result = 0
		@ident_table = {}
	end

	def visit_plus_exp(exp)
		left,right = left_and_right(exp)
		@result = left + right
	end

	def visit_minus_exp(exp)
		left,right = left_and_right(exp)
		@result = left - right
	end

	def visit_mul_exp(exp)
		left,right = left_and_right(exp)
		@result = left * right
	end

	def visit_div_exp(exp)
		left,right = left_and_right(exp)
		@result = left / right
	end

	def visit_num_exp(exp)
		@result = exp.value
	end

	def visit_assign_ident_exp(exp)
		exp.value.accept(self)
		ident_table[exp.name] = @result
	end

	def visit_ident_exp(exp)
		@result = ident_table[exp.value]
	end

	def result
		result = @result
		@result = 0
		return result
	end

	private

	def left_and_right(exp)
		exp.left.accept(self)
	 	left = @result
		
		exp.right.accept(self)
		right = @result
		[left,right]
	end
end
