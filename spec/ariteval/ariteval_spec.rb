require File.dirname(__FILE__) + '/../spec_helper'
require 'ariteval'

describe "An Ariteval should evaluate" do
	
  before(:each) do
    @ariteval = Ariteval.new
  end

  it "a single complex expression" do
    expression = "3 * (4 - 2) + 5*(4/2)/(3-2)"
    @ariteval.evaluate(expression).should == eval(expression)
  end

  it "two different expressions" do
    exp1 = "5 - 32"
    exp2 = "3*(2-4)"

    @ariteval.evaluate(exp1).should == eval(exp1)
    @ariteval.evaluate(exp2).should == eval(exp2)
  end
end

describe "An Ariteval should be able to parse" do

  before(:each) do
    @parser = Ariteval.new
    @parser.should respond_to(:parse)
    @parser.scanner.should be_kind_of(Buffer)
  end
	
  it "'1 + 1 + 1'" do
    result = @parser.parse('1+ 1 + 1')

    result.to_s.should == "( ( 1 + 1 ) + 1 )"
  end

  it "'5 - 1 - 2'" do
    result = @parser.parse('5 - 1 - 2')

    result.to_s.should == "( ( 5 - 1 ) - 2 )"
  end

  it "'1 + 5 * 3'" do
    @parser.parse('1 + 5 * 3').to_s.should == "( 1 + ( 5 * 3 ) )"
  end

  it "'5 * 3 / 2'" do
    @parser.parse('5 * 3 / 2').to_s.should == "( ( 5 * 3 ) / 2 )"
  end

  it "'5 * ( 4 + 1 )'" do
    @parser.parse('5 * ( 4 + 1 )').to_s.should == "( 5 * ( 4 + 1 ) )"
  end

  it "'( 3 - 4 ) * ( 3 + 2 )'" do
    @parser.parse('( 3 - 4 ) * ( 3 + 2 )').to_s.should == '( ( 3 - 4 ) * ( 3 + 2 ) )' 
  end

  it "twice" do
    result = @parser.parse("1+1+1")

    result.to_s.should == "( ( 1 + 1 ) + 1 )"
	
    result = @parser.parse("5-1-2")

    result.to_s.should == "( ( 5 - 1 ) - 2 )"
  end

  it "a = 5" do
    Ariteval.parser.productions[:factor].tokens[[:ident,:assign]].should_not be_nil
    @parser.scanner.should respond_to(:lookahead)
    @parser.parse("a = 5").to_s.should == "( a = 5 )"
  end
	
  it "a + 5" do
    @parser.parse("a + 5").to_s.should == "( a + 5 )"
  end

  it "'( a = 3 * 2 ) - ( 24 + a )'" do
    @parser.parse('( a = 3 * 2 ) - ( 24 + a )').to_s.should == "( ( a = ( 3 * 2 ) ) - ( 24 + a ) )"
  end
  
  it "' 3 + 2'" do
    @parser.parse(' 3 + 2').to_s.should == "( 3 + 2 )"
  end
end

describe "An Ariteval shouldn't be able to parse" do
	
  before(:each) do
    @parser = Ariteval.new
  end

  it "'1 + +'" do
    lambda { @parser.parse('1 + +') }.should raise_error(ParserError)
  end

  it "'- 1'" do
    lambda { @parser.parse('- 1') }.should raise_error(ParserError)
  end

  it "'* 2'" do
    lambda { @parser.parse('* 2') }.should raise_error(ParserError)
  end
	
  it "'2 /'" do
    lambda { @parser.parse('2 /') }.should raise_error(ParserError)
  end

  it "'2 * ( 1 + 3'" do
    lambda { @parser.parse('2 * ( 1 + 3') }.should raise_error(ParserError)
  end
	
end
