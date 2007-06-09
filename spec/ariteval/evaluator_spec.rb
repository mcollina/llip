require File.dirname(__FILE__) + '/../spec_helper'
require 'evaluator'
require 'buffer'


describe 'An Evaluator' do
	
  before(:each) do
    @eval = Evaluator.new
  end

  it "should be able to visit all the elements" do
    @eval.should respond_to(:visit_num_exp)
    @eval.should respond_to(:visit_plus_exp)
    @eval.should respond_to(:visit_minus_exp)
    @eval.should respond_to(:visit_mul_exp)
    @eval.should respond_to(:visit_div_exp)
  end

  it "should return the computated result" do
    @eval.should respond_to(:result)
  end
end

describe "An Evaluator should be able to eval" do

  before(:each) do
    @eval = Evaluator.new
    @parser = Ariteval.new
  end
	
  it "a NumExp" do
    num = mock "NumExp"
    num.should_receive(:value).and_return(5)

    @eval.visit_num_exp(num)
    @eval.result.should be_equal(5)
  end
	
  it "a PlusExp" do
    @parser.parse("1 + 1").accept(@eval)
    @eval.result.should == 2
  end

  it "a MinusExp" do
    @parser.parse("5 - 1").accept(@eval)
    @eval.result.should == 4
  end
	
  it "a MulExp" do
    @parser.parse("5 * 2").accept(@eval)
    @eval.result.should == 10
  end

  it "a DivExp" do
    @parser.parse("4 / 2").accept(@eval)
    @eval.result.should == 2
  end

  it "a complex expression" do
    expression = "3 * (4 - 2) + 5*(4/2)/(3-2)"
		
    exp = PlusExp.new(
    MulExp.new(
    NumExp.new(3),
    MinusExp.new(
    NumExp.new(4),
    NumExp.new(2)
    )
    ),
    DivExp.new(
    MulExp.new(
    NumExp.new(5),
    DivExp.new(
    NumExp.new(4),
    NumExp.new(2)
    )
    ),
    DivExp.new(
    NumExp.new(3),
    NumExp.new(2)
    )
    )
    )
		
    exp.accept(@eval)
    @eval.result.should == eval(expression)
  end

  it "should have a ident_table" do
    @eval.should respond_to(:ident_table)
    @eval.ident_table.should == {}
  end

  it "an AssignIdentExp" do
    @parser.parse("a = 4").accept(@eval)
    @eval.result.should == 4
    @eval.ident_table["a"].should == 4
  end

  it "an IdentExp" do
    @eval.ident_table["a"] = 5
    @parser.parse("a").accept(@eval)
    @eval.result.should == @eval.ident_table["a"]
  end
end
