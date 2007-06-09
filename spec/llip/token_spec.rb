require File.dirname(__FILE__) + '/../spec_helper'
require 'token'

describe "A token" do 
	
  before(:each) do
    @token = Token.new(:my_type,"my value")
  end

  it "should have a name" do
    @token.should respond_to(:type)
    @token.name.should == :my_type
  end

  it "should have a value" do
    @token.should respond_to(:value)
    @token.value.should == "my value"
  end

  it "can be coerced to a string" do
    @token.should respond_to(:to_str)
    @token.should respond_to(:to_s)

    @token.to_s.should == "my value"
    @token.to_str.should == "my value"
  end

  it "can be a value = nil and it must respond correctly to nil?" do
    @token = Token.new(:my_type,nil)
    @token.should be_nil
  end
	
  it "should have :nil,nil as default values for type,value" do
    @token = Token.new
    @token.value.should == nil
    @token.name.should == :nil
  end

  it "should behave correctly when called ==" do
    t2 = Token.new(:my_type,"my value")
    @token.should == t2

    @token.should == "my value"

    @token.should == :my_type

    @token.should == :everything
  end

  it "should be matched with a regexp" do
    (@token =~ /.*value/).should_not be_nil
    (@token !~ /.*value/).should == false
  end

  it "should have a line attribute, which is initialized to -1" do
    @token.should respond_to(:line)
    @token.line.should == -1

    lambda { @token = Token.new(:my_type, "my value", 5) }.should_not raise_error
    @token.line.should == 5
  end

  it "should have a char attribute, which is initialized to -1" do
    @token.should respond_to(:char)
    @token.char.should == -1

    lambda { @token = Token.new(:my_type, "my value", 5,7) }.should_not raise_error
    @token.char.should == 7
  end
end
