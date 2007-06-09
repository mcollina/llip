require File.dirname(__FILE__) + '/../spec_helper'
require 'production_specification'

describe "A ProductionSpecification" do
  
  before(:each) do 
    @production = ProductionSpecification.new(:test_production)
  end

  it "should have a name" do
    @production.should respond_to(:name)
    @production.name.should == :test_production
  end

  it "should allow to specify a recognized token with a block parameter" do
    @production.should respond_to(:token)
    lambda { @production.token(:token_name) { "hello" } }.should_not raise_error
  end

  it "should have some tokens" do
    @production.should respond_to(:tokens)
    @production.tokens.should == {}
  
    first_block = lambda { :first_block }
    second_block = lambda { :second_block }
    @production.token(:first_token,&first_block)
    @production.token(:second_token,second_block)

    @production.tokens[:first_token].should == first_block
    @production.tokens[:second_token].should == second_block
  end

  it "should have a 'mode' attribute with a default (:single)" do
    @production.should respond_to(:mode)
    @production.mode.should == :single
    
    @production.should respond_to(:mode=)
    @production.mode= :recursive
    @production.mode.should == :recursive
  end

  it "should have a default result" do
    @production.should respond_to(:default)
    @production.default.should respond_to(:call)
    @production.default.call.should be_nil

    called = false
    @production.default { called = true }
    @production.default.call
    called.should == true

    block = mock "block"
    block.should_receive(:call)
    @production.default(block)
    @production.default.call
  end

  it "should accept as a token an array" do
    @production.token([:first,:second])
    @production.tokens.has_key?([:first,:second]).should be_true
  end

  it "should assume that a lot of symbols as arguments are an array" do
    @production.token :first, :second
    @production.tokens.has_key?([:first,:second]).should be_true
  end

  it "should have a :raise_on_error attribute with true as a default" do
    @production.should respond_to(:raise_on_error)
    @production.should respond_to(:raise_on_error=)
    @production.raise_on_error.should == true
    @production.raise_on_error=false
    @production.raise_on_error.should == false
  end
end
