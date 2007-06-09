require File.dirname(__FILE__) + '/../spec_helper'
require 'production_compiler'

describe "A ProductionCompiler" do
	
  before(:each) do
    @compiler = ProductionCompiler.new
  end

  it "should have a code method which returns a String" do
    @compiler.should respond_to(:code)
    @compiler.code.should == ""
  end

  it "should have a start method which accept a name and build the definition of a method" do
    @compiler.should respond_to(:start)
    @compiler.start(:new_production)
    @compiler.code.strip.should =~ /^def parse_new_production$/
    @compiler.code.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].default.call\(@scanner,self\)\n*$/
  end

  it "should have an end method which close the definition of a method" do
    @compiler.should respond_to(:end)
    @compiler.start(:new_production)
    @compiler.end
    @compiler.code.strip.should =~ /^def parse_new_production$/
    @compiler.code.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].default.call\(@scanner,self\)\n*$/
    @compiler.code.should =~ /^( |\t|\n)*return result\n*$/
    @compiler.code.strip.should =~ /^( |\t|\n)*end$/
  end

  it "should build an 'if'..'elsif' block for a sequence of tokens" do
		
    @compiler.start(:new_production)
    @compiler.token(:first_token)
    @compiler.token(:second_token)
    @compiler.code.strip.should =~ /^( |\t|\n)*if @scanner.current == :"first_token"$/
    @compiler.code.strip.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].tokens\[:"first_token"\].call\(result,@scanner,self\)$/
    @compiler.code.strip.should =~ /^( |\t|\n)*elsif @scanner.current == :"second_token"$/
    @compiler.code.strip.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].tokens\[:"second_token"\].call\(result,@scanner,self\)$/
  end
	
  it "should build an 'if'..'elsif' block for a sequence of tokens" do
    @compiler.start(:new_production)
    @compiler.token("token")
    @compiler.code.strip.should =~ /^( |\t|\n)*if @scanner.current == 'token'$/
    @compiler.code.strip.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].tokens\['token'\].call\(result,@scanner,self\)$/
  end
	
  it "should close the 'if' block with an appropriate raising 'else' clause as a default" do
    @compiler.start(:new_production)
    @compiler.token(:first_token)

    lambda { @compiler.end }.should_not raise_error
		
    @compiler.code.strip.should =~ /^( |\t|\n)*if @scanner.current == :"first_token"$/
    @compiler.code.strip.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].tokens\[:"first_token"\].call\(result,@scanner,self\)$/
    @compiler.code.strip.should =~ /^( |\t|\n)*else$/
    @compiler.code.strip.should =~ /^( |\t|\n)*raise NotAllowedTokenError.new\(@scanner.current,:"new_production"\)( |\t|\n)*end$/
  end

  it "should close the 'if' block without an 'else' clause if it's specified so" do
    @compiler.start(:new_production)
    @compiler.token(:first_token)

    lambda { @compiler.end(false) }.should_not raise_error
		
    @compiler.code.strip.should =~ /^( |\t|\n)*if @scanner.current == :"first_token"$/
    @compiler.code.strip.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].tokens\[:"first_token"\].call\(result,@scanner,self\)( |\t|\n)*end$/
  end

  it "should produce an 'if'..'elsif' block containing lookaheads" do
    @compiler.start(:new_production)
    @compiler.token(["token","first","second"])
    @compiler.token(["token","first"])
    @compiler.token(["token","second"])
    @compiler.code.strip.should =~ /^( |\t|\n)*if @scanner.current == 'token' and @scanner.lookahead\(1\) == 'first' and @scanner.lookahead\(2\) == 'second'$/
    @compiler.code.strip.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].tokens\[\['token','first','second'\]\].call\(result,@scanner,self\)$/
    @compiler.code.strip.should =~ /^( |\t|\n)*elsif @scanner.current == 'token' and @scanner.lookahead\(1\) == 'first'$/
    @compiler.code.strip.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].tokens\[\['token','first'\]\].call\(result,@scanner,self\)$/
    @compiler.code.strip.should =~ /^( |\t|\n)*elsif @scanner.current == 'token' and @scanner.lookahead\(1\) == 'second'$/
    @compiler.code.strip.should =~ /^( |\t|\n)*result = productions\[:"new_production"\].tokens\[\['token','second'\]\].call\(result,@scanner,self\)$/
  end

  it "should not modify the lookaheads tokens" do
    @compiler.start(:new_production)
    lookahead = ["token","first","second"]
    @compiler.token(lookahead)
    lookahead.should == ["token","first","second"]
  end

  it "should produce code that doesn't raise Exceptions if evaluated" do
    @compiler.start(:fake)
    @compiler.token(:first)
    @compiler.token(:second)
    @compiler.token(:third)
    @compiler.token([:fourth,:lk])
    @compiler.token(:fourth)
    @compiler.end

    @class = Class.new
    lambda { @class.class_eval(@compiler.code) }.should_not raise_error
  end

  it "should have a reset method which clean the code" do
    @compiler.should respond_to(:reset)
    @compiler.code.should == ""
    @compiler.start(:fake)
    @compiler.token(:first)
    @compiler.token(:second)
    @compiler.token(:third)
    @compiler.end
    @compiler.code.should_not == ""
    @compiler.reset
    @compiler.code.should == ""
  end

  it "should have a compile method which accept a ProductionSpecification and create the code" do
    @compiler.should respond_to(:compile)

    @production = mock "ProductionSpecification"
    @production.should_receive(:name).and_return(:fake)
    @production.should_receive(:tokens).and_return({ :first => nil, :second => nil, :third => nil})
    @production.should_receive(:raise_on_error).and_return(false)

    @compiler.should_receive(:start).with(:fake)
    @compiler.should_receive(:token).with(:first)	
    @compiler.should_receive(:token).with(:second)	
    @compiler.should_receive(:token).with(:third)
    @compiler.should_receive(:end).with(false)

    @compiler.compile(@production)	
  end

  it "should compile a lookahead production correctly" do
    @compiler.should respond_to(:compile)

    @production = mock "Production"
    @production.should_receive(:name).and_return(:fake)
    @production.should_receive(:tokens).and_return({ [:look,"3"] => nil, [:look,"1"] => nil, :look => nil})
    @production.should_receive(:raise_on_error).and_return(true)

    @compiler.should_receive(:start).with(:fake)
    @compiler.should_receive(:token).with([:look,"3"])	
    @compiler.should_receive(:token).with([:look,"1"])
    @compiler.should_receive(:token).with(:look)	
    @compiler.should_receive(:end).with(true)

    @compiler.compile(@production)	
  end

  it "should have a method to sort the productions correctly" do
    @compiler.should respond_to(:sort_production)
		
    @production = mock "Production"
    @production.should_receive(:tokens).and_return({ [:look,"1"] => nil, [:look,"3","2"] => nil, :everything => nil, :look => nil})
		
    @compiler.sort_production(@production).should == [[:look,"3","2"],[:look,"1"], :look, :everything]
  end
end


describe "The code produced by a ProductionCompiler without lookaheads" do
	
  before(:each) do
    @compiler = ProductionCompiler.new
    @compiler.start(:fake)
    @compiler.token(:first)
    @compiler.token(:second)
    @compiler.token(:third)
    @compiler.token("+")
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
      :third => mock('third'),
      "+" => mock('+')
    }
    @instance.productions[:fake].should_receive(:tokens).any_number_of_times.and_return(@tokens)
    @instance.scanner = mock 'scanner'
    @instance.scanner.should_receive(:next).any_number_of_times

    @default = mock "default"
    @instance.productions[:fake].should_receive(:default).any_number_of_times.and_return(@default)
    @default.should_receive(:call).and_return(nil)
  end

  it "should call the specified block when received the correct token" do
    @instance.scanner.should_receive(:current).and_return(:first)
    @tokens[:first].should_receive(:call).with(nil,@instance.scanner,@instance)
    @instance.parse_fake
  end
	
  it "should call the specified block even if the token is a string" do
    @instance.scanner.should_receive(:current).exactly(4).and_return("+")
    @tokens["+"].should_receive(:call).with(nil,@instance.scanner,@instance)
    @instance.parse_fake
  end
	
  it "should call the specified block and return the correct value" do
    @tokens[:second] = lambda { |result,scanner,parser| :ok }
    @instance.scanner.should_receive(:current).twice.and_return(:second)
    @instance.parse_fake.should == :ok
  end

  it "should raise an exception if the token isn't recognized" do
    token = mock "Token"
    token.should_receive(:value).and_return("value")
    token.should_receive(:name).and_return(:a_name)
    @instance.scanner.should_receive(:current).exactly(@tokens.size + 1).times.and_return(token)
    lambda { @instance.parse_fake }.should raise_error(NotAllowedTokenError)
  end
end

describe "The code produced by a ProductionCompiler with lookaheads" do
	
  before(:each) do
    @compiler = ProductionCompiler.new
    @compiler.start(:fake)
    @compiler.token([:token,:first,:third])
    @compiler.token([:token,:second])
    @compiler.token([:token,:third])
    @compiler.token(:token)
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
      [:token,:first,:third] => mock('first'),
      [:token,:second] => mock('second'),
      [:token,:third] => mock('third'),
      :token => mock('token')
    }
    @instance.productions[:fake].should_receive(:tokens).any_number_of_times.and_return(@tokens)
    @instance.scanner = mock 'scanner'
    @scanner = @instance.scanner

    @default = mock "default"
    @instance.productions[:fake].should_receive(:default).any_number_of_times.and_return(@default)
    @default.should_receive(:call).and_return(nil)
  end

  it "should recognize the sequence [:token,:first,:third]" do
    @scanner.should_receive(:current).once.and_return(:token)
    @scanner.should_receive(:lookahead).with(1).once.and_return(:first)
    @scanner.should_receive(:lookahead).with(2).once.and_return(:third)
		
    @tokens[[:token,:first,:third]].should_receive(:call).with(nil,@scanner,@instance)

    @instance.parse_fake
  end
end
