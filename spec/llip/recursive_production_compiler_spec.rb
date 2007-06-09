require File.dirname(__FILE__) + '/../spec_helper'
require 'recursive_production_compiler'

describe "A RecursiveProductionCompiler" do
	
  before(:each) do
    @compiler = RecursiveProductionCompiler.new
  end

  it "should add to the 'start' and 'end' method a behaviour that add a while cycle to the code" do
    @compiler.should respond_to(:start)
    @compiler.start(:new_production)
    @compiler.end

    @compiler.code.strip.should =~ /^def parse_new_production$/
    @compiler.code.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].default.call\(@scanner,self\)\n*$/
    @compiler.code.should =~ /^( |\t|\n)*while not @scanner\.current\.nil\?\n(.|\t|\n)*end$/
    @compiler.code.should =~ /^( |\t|\n)*return result\n*$/
    @compiler.code.strip.should =~ /^( |\t|\n)*end$/
  end

  it "should modify the 'else' behaviour to break, instead of raise" do
    @compiler.start(:new_production)
    @compiler.token(:first_token)

    lambda { @compiler.send(:build_else) }.should_not raise_error
		
    @compiler.code.strip.should =~ /^( |\t|\n)*if @scanner.current == :"first_token"$/
    @compiler.code.strip.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].tokens\[:"first_token"\].call\(result,@scanner,self\)$/
    @compiler.code.strip.should =~ /^( |\t|\n)*else$/
    @compiler.code.strip.should =~ /^( |\t|\n)*break\n( |\t|\n)*end$/
  end
	
  it "should produce code that doesn't raise Exceptions if evaluated" do
    @compiler.start(:fake)
    @compiler.token(:first)
    @compiler.token(:second)
    @compiler.token(:third)
    @compiler.end
		
    @class = Class.new
    lambda { @class.class_eval(@compiler.code) }.should_not raise_error
  end
end

describe "The code produced by RecursiveProductionCompiler" do
	
  before(:each) do
    @compiler = RecursiveProductionCompiler.new
    @compiler.start(:fake)
    @compiler.token(:first)
    @compiler.token(:second)
    @compiler.token(:third)
    @compiler.end

    @class = Class.new
    lambda { @class.class_eval(@compiler.code) }.should_not raise_error
    @class.class_eval <<-CODE 
			attr_accessor :productions
			attr_accessor :scanner
		CODE
    @instance = @class.new
    @instance.productions = {
      :fake => mock("ProductionSpecification")
    }
    @tokens = {  
      :first => mock('first'),
      :second => mock('second'),
      :third => mock('third')
    }
    @instance.productions[:fake].should_receive(:tokens).any_number_of_times.and_return(@tokens)
    @instance.scanner = mock 'scanner'
    @instance.scanner.should_receive(:next).any_number_of_times
	
    @default = mock "default"
    @instance.productions[:fake].should_receive(:default).any_number_of_times.and_return(@default)
    @default.should_receive(:call).and_return(nil)
  end

  it "should call the specified block the number of times the token is given" do
    @instance.scanner.should_receive(:current).exactly(7).times.and_return(*([:first]*6 + [nil]))
    @tokens[:first].should_receive(:call).exactly(3).times.and_return("hello")
    lambda { @instance.parse_fake.should == "hello" }.should_not raise_error
  end
end

