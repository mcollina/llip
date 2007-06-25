require File.dirname(__FILE__) + '/../spec_helper'

describe "An LLIPError" do

  before(:each) do
    @instance = LLIPError.new(:a_token)
  end

  it "should have a Token and a optional message as initialization arguments" do
    lambda { @instance = LLIPError.new }.should raise_error(ArgumentError)	
    lambda { @instance = LLIPError.new(:a_token,"a message") }.should_not raise_error
  end

  it "should have a :token attribute" do
    @instance.should respond_to(:token)
    @instance.token.should == :a_token
  end

  it "should add information about the line and the char from the token to the message" do
    token = mock("Token")
    @instance = LLIPError.new(token,"this is a fake error message.")
    token.should_receive(:line).and_return(1)
    token.should_receive(:char).and_return(5)

    @instance.to_s.should == "At line 1 char 5 a LLIP::LLIPError occurred: this is a fake error message."
  end
end

describe "An instance of a class descending from LLIPError" do

  before(:each) do
    @class = Class.new(LLIPError)
  end

  it "should have the right to_s method" do
    @class.should_receive(:name).and_return("FakeLLIPError")
		
    token = mock("Token")
    @instance = @class.new(token,"this is a fake error message.")
    token.should_receive(:line).and_return(1)
    token.should_receive(:char).and_return(5)

		
    @instance.to_s.should == "At line 1 char 5 a FakeLLIPError occurred: this is a fake error message."
  end
end

describe "A UnvalidTokenError" do
	
  it "should have a correct to_s method " do
    token = mock("Token")
    token.should_receive(:line).and_return(1)
    token.should_receive(:char).and_return(5)
    token.should_receive(:value).and_return("a")
    token.should_receive(:name).and_return(:a_regexp)

    @instance = UnvalidTokenError.new(token)
    @instance.to_s.should == "At line 1 char 5 a LLIP::UnvalidTokenError occurred: the current token 'a' doesn't match with the regular expression a_regexp."
  end

end

describe "A NotAllowedTokenError" do
	
  it "should have a correct to_s method " do
    token = mock("Token")
    token.should_receive(:line).and_return(1)
    token.should_receive(:char).and_return(5)
    token.should_receive(:value).and_return("a")
    token.should_receive(:name).and_return(:a_regexp)

    lambda { @instance = NotAllowedTokenError.new(token,:a_production) }.should_not raise_error
    @instance.to_s.should == "At line 1 char 5 a LLIP::NotAllowedTokenError occurred: the token 'a' matched by the regexp 'a_regexp' isn't allowed in production a_production."
  end

end
