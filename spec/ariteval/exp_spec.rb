require File.dirname(__FILE__) + '/../spec_helper'
require 'exp'

describe "A NumExp" do
  before(:each) do 
    @num = NumExp.new(5)
  end

  it "should return its value" do
    @num.should respond_to(:value)

    @num.value.should be_equal(5)
  end

  it "should return its value as a String" do
    @num.to_s.should == "5"
  end
	
  it "should call visitor.visit_num_exp in 'accept'" do
    visitor = mock("Visitor")
    visitor.should_receive(:visit_num_exp).with(@num)
    @num.accept(visitor)
  end
end

describe "A IdentExp" do
	
  before(:each) do
    @ident = IdentExp.new("a")
  end

  it "should return its value" do
    @ident.should respond_to(:value)

    @ident.value.should == "a"
  end

  it "should be coerced to a String" do
    @ident.to_s.should == @ident.value
  end

  it "should call visitor.visit_ident_exp in 'accept'" do
    visitor = mock("Visitor")
    visitor.should_receive(:visit_ident_exp).with(@ident)
    @ident.accept(visitor)
  end

end

describe "An AssignIdentExp" do
	
  before(:each) do
    @assign = AssignIdentExp.new("a",5)
  end

  it "should return its name" do
    @assign.should respond_to(:name)
    @assign.name.should == "a"
  end

  it "should be coerced to a String" do
    @assign.to_s.should == "( a = 5 )"
  end

  it "should call visitor.visit_assign_ident_exp in 'accept'" do
    visitor = mock("Visitor")
    visitor.should_receive(:visit_assign_ident_exp).with(@assign)
    @assign.accept(visitor)
  end
end

describe "OpExp", :shared => true do

  it "should have a left and a right child" do
    @exp.should respond_to(:left)
    @exp.should respond_to(:right)
	
    @exp.left.should be_equal(:left)
    @exp.right.should be_equal(:right)
  end

  it "should respond to 'op'" do
    @exp.should respond_to(:op)
  end

  it "should be represented by a String" do
    @exp.should_receive(:op).and_return("op")

    @exp.to_s.should == "( left op right )"
  end
end

describe "An OpExp" do
  it_should_behave_like "OpExp"
  
  before(:each) do
    @exp = OpExp.new(:left,:right)
  end
  
  it "should not be equal to another one with different values" do
    @exp.should_not == "ciao"

    new_exp = OpExp.new(:different_left,:different_right)
    @exp.should_not == new_exp
  end

  it "should be equal to another one with the same values" do
    new_exp = OpExp.new(:left,:right)
    @exp.should == new_exp
  end
end

describe "A PlusExp" do
  
  it_should_behave_like "OpExp"
  
  before(:each) do
    @exp = PlusExp.new(:left,:right)
  end

  it "should have op = '+'" do
    @exp.op.should == "+"
  end

  it "should call visitor.visit_plus_exp in 'accept'" do
    visitor = mock("Visitor")
    visitor.should_receive(:visit_plus_exp).with(@exp)
    @exp.accept(visitor)
  end
end

describe "A MinusExp" do 
  
  it_should_behave_like "OpExp"
  
  before(:each) do
    @exp = MinusExp.new(:left,:right)
  end
	
  it "should have op = '-'" do
    @exp.op.should == "-"
  end
	
  it "should call visitor.visit_minus_exp in 'accept'" do
    visitor = mock("Visitor")
    visitor.should_receive(:visit_minus_exp).with(@exp)
    @exp.accept(visitor)
  end
end

describe "A MulExp" do
  
  it_should_behave_like "OpExp"
  
  before(:each) do
    @exp = MulExp.new(:left,:right)
  end
	
  it "should have op = '*'" do
    @exp.op.should == "*"
  end
	
  it "should call visitor.visit_mul_exp in 'accept'" do
    visitor = mock("Visitor")
    visitor.should_receive(:visit_mul_exp).with(@exp)
    @exp.accept(visitor)
  end
end

describe "A DivExp" do
  
  it_should_behave_like "OpExp"
  
  before(:each) do
    @exp = DivExp.new(:left,:right)
  end
	
  it "should have op = '/'" do
    @exp.op.should == "/"
  end
	
  it "should call visitor.visit_div_exp in 'accept'" do
    visitor = mock("Visitor")
    visitor.should_receive(:visit_div_exp).with(@exp)
    @exp.accept(visitor)
  end
end

describe "Using all the exp you should be able to represent" do
  it "'3-5'" do
    exp = MinusExp.new(NumExp.new(3),NumExp.new(5))
		
    exp.to_s.should == "( 3 - 5 )"
  end

  it "'2+5*4-1'" do
    exp = MinusExp.new(
      PlusExp.new(
        NumExp.new(2),
        MulExp.new(NumExp.new(5),NumExp.new(4))
      ),
      NumExp.new(1)
    )
		
    exp.to_s.should == "( ( 2 + ( 5 * 4 ) ) - 1 )"
  end

  it "'3-5-1*5'" do
    exp = MinusExp.new(
        NumExp.new(3),
        MinusExp.new(
          NumExp.new(5),
          MulExp.new(NumExp.new(1),NumExp.new(5))
        )
    )

    exp.to_s.should == "( 3 - ( 5 - ( 1 * 5 ) ) )"
  end

  it "'a = 5'" do
    exp = AssignIdentExp.new('a',NumExp.new(5))
    exp.to_s.should == "( a = 5 )"
  end

  it "'( a = 3 * 2 ) - ( 24 + a )'" do
    exp = MinusExp.new(
      AssignIdentExp.new("a", MulExp.new(NumExp.new(3),NumExp.new(2))),
      PlusExp.new(NumExp.new(24),IdentExp.new("a"))
    )
    exp.to_s.should == "( ( a = ( 3 * 2 ) ) - ( 24 + a ) )"
  end
end
