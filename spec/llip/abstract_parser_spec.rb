require File.dirname(__FILE__) + '/../spec_helper'

describe "A class descending from AbstractParser" do

  before(:each) do
    @class = Class.new(AbstractParser)
    if @class.respond_to? :autocompile
      @class.autocompile(false)
    end
    @parser = @class.new
  end

  it "should raise an exception if it hasn't been compiled" do
    lambda { @parser.parse(:mock) }.should raise_error(RuntimeError)
  end

  it "should have hash-like capabilities" do
    @parser.should respond_to(:[])
    @parser.should respond_to(:[]=)

    @parser[:var]= :foo
    @parser[:var].should == :foo
  end

  it "should be able to specify a production with a name (and in case the mode), some tokens and blocks" do
    @class.should respond_to(:production)

    lambda do
      @class.production(:name) do |prod| 
        prod.token(:first_token) { "first" }
        prod.token(:second_token) { "second" }
      end
    end.should_not raise_error


    l = lambda do 
      @class.production(:name,:mode) do |prod| 
        prod.mode.should == :mode
        prod.token(:first_token) { "first" }
        prod.token(:second_token) { "second" }
      end
    end
    l.should_not raise_error
  end
	
  it "should memorize its productions in a hash of ProductionSpecification" do
    @class.should respond_to(:productions)
    @class.productions.should == {}
		
    @class.production(:name) do |prod| 
      prod.token(:first_token) { "first" }
      prod.token(:second_token) { "second" }
    end	
	
    @class.productions[:name].should be_kind_of(ProductionSpecification)
    @class.productions[:name].tokens[:first_token].should_not be_nil
    @class.productions[:name].tokens[:second_token].should_not be_nil
  end

  it "should memorize the scope" do
    @class.should respond_to(:scope)
    @class.scope.should be_nil

    @class.scope(:a_new_scope)
    @class.scope.should == :a_new_scope
  end
	
  it "should have an 'autocompile' attribute" do
    @class.should respond_to(:autocompile)
    @class.autocompile.should == false
    lambda { @class.autocompile(true) }.should_not raise_error
    @class.autocompile.should == true
    lambda { @class.autocompile(false) }.should_not raise_error
    @class.autocompile.should == false
  end

  it "should have a code attribute" do
    @class.should respond_to(:code)
    @class.code.should be_nil
    @class.scope(:a_scope)
    @class.production(:a_scope) {}
    @class.compile
    @class.code.should_not == ""
  end

  it "should initialize and fill 'code' when 'autocompile' is true" do
    @class.autocompile false
    @class.code.should be_nil
    @class.autocompile true
    @class.code.should == ""
    @class.scope(:a_scope)
    @class.code.should_not == ""
    @class.production(:a_scope) {}
    @class.code.should_not == ""
  end

  it "should raise if a production has an unknown mode" do
    l = lambda {
      @class.scope :first	
      @class.production(:first) { |p| p.mode = :error_mode }
      @class.compile	
    }
    l.should raise_error(RuntimeError)
  end
end

describe "A class descending from AbstractParser with some productions specified" do
	
  before(:each) do
    @class = Class.new(AbstractParser)
    if @class.respond_to? :autocompile
      @class.autocompile(false)
    end
    @parser = @class.new

    @mock_single = mock "Single"
    @mock_single.should_receive(:respond_to?).with(:to_ary).and_return(false)
    @mock_single.should_receive(:respond_to?).with(:call).and_return(true)
    @class.production(:single) do |prod|
      prod.token(:single_token,@mock_single) 
    end
		
    @mock_recursive = mock "Recursive"
    @mock_recursive.should_receive(:respond_to?).with(:to_ary).and_return(false)
    @mock_recursive.should_receive(:respond_to?).with(:call).and_return(true)
    @class.production(:recursive) do |prod|
      prod.mode=:recursive
      prod.token(:recursive_token,@mock_recursive) 
    end
		
    @class.should respond_to(:compile)
    @class.should respond_to(:compiled)
  end

  it "should be compiled with a scope specified" do
    @class.scope(:single)
	
    @class.compiled.should == false
    lambda { @class.compile }.should_not raise_error
    @class.compiled.should == true
  end

  it "shouldn't be compiled without a correct scope" do
	
    @class.compiled.should == false
    lambda { @class.compile }.should raise_error(RuntimeError)
    @class.compiled.should == false
		
    @class.scope(:fake_scope)
    @class.compiled.should == false
    lambda { @class.compile }.should raise_error(RuntimeError)
    @class.compiled.should == false

  end

  it "shouldn't be compiled if a production has an invalid mode" do
    @class.production(:error) { |prod| prod.mode = :this_is_an_invalid_mode }
    lambda { @class.compile }.should raise_error(RuntimeError)
  end

  it "should mantain an attribute 'code' which mantains the built code" do
    @class.scope(:single)
		
    @class.should respond_to(:code)
    @class.code.should be_nil
    lambda { @class.compile }.should_not raise_error
    @class.code.should_not be_nil
    @class.code.should be_kind_of(String)
  end

end

describe "An instance of a class descending from AbstractParser with some productions specified after being compiled" do

  before(:each) do
    @class = Class.new(AbstractParser)
    if @class.respond_to? :autocompile
      @class.autocompile(false)
    end
    @parser = @class.new
		
    @class.scope :single

    @mock_single = mock "Single"
    @mock_single.should_receive(:respond_to?).with(:to_ary).and_return(false)
    @mock_single.should_receive(:respond_to?).with(:call).and_return(true)
    @class.production(:single) do |prod|
      prod.token(:single_token,@mock_single) 
    end
		
    @mock_recursive = mock "Recursive"
    @mock_recursive.should_receive(:respond_to?).with(:to_ary).and_return(false)
    @mock_recursive.should_receive(:respond_to?).with(:call).and_return(true)
    @class.production(:recursive) do |prod|
      prod.mode = :recursive
      prod.token(:recursive_token,@mock_recursive) 
    end
		
    lambda { @class.compile }.should_not raise_error
  end

  it "should expose parse_NAME methods" do
    @parser.should respond_to("parse_single")
    @parser.should respond_to("parse_recursive")
  end

  it "should have a productions method which alias the class one" do
    @parser.should respond_to(:productions)
    @parser.productions.should == @class.productions
  end

  it "should have a parse method which accept a scanner" do
    @parser.should respond_to(:parse)

    scanner = mock "Scanner"
    scanner.should_receive(:next).any_number_of_times
    scanner.should_receive(:current).twice.and_return(:single_token,nil)

    @mock_single.should_receive(:call).with(nil,scanner,@parser).and_return(:good_result)

    lambda { @parser.parse(scanner).should == :good_result }.should_not raise_error
		
    scanner = mock "Scanner2"
    scanner.should_receive(:next).any_number_of_times
    scanner.should_receive(:current).exactly(5).and_return(:single_token)
		
    @mock_single.should_receive(:call).with(nil,scanner,@parser).and_return(:good_result)
		
    lambda { @parser.parse(scanner) }.should raise_error(ParserError)
  end

end

describe "A class descending from AbstractParser should autocompile" do
	
  before(:each) do
    @class = Class.new(AbstractParser)
    @parser = @class.new
    #@class.autocompile true
  end

  it "the scope" do
    @class.scope :scope
    @parser.should respond_to(:parse)
    @parser.should_receive(:parse_scope).once
    scanner = mock "Scanner"
    scanner.should_receive(:next).once
    scanner.should_receive(:current).once
    @parser.parse(scanner)
  end

  it "a 'single' production" do
    @mock_single = mock "Single"
    @mock_single.should_receive(:respond_to?).with(:to_ary).and_return(false)
    @mock_single.should_receive(:respond_to?).with(:call).and_return(true)
    @class.production(:single) do |prod|
      prod.token(:single_token,@mock_single) 
    end
    @parser.should respond_to(:parse_single)
  end
	
  it "a 'recursive' production" do
    @mock_recursive = mock "Recursive"
    @mock_recursive.should_receive(:respond_to?).with(:to_ary).and_return(false)
    @mock_recursive.should_receive(:respond_to?).with(:call).and_return(true)
    @class.production(:recursive) do |prod|
      prod.mode = :recursive
      prod.token(:recursive_token,@mock_recursive) 
    end
    @parser.should respond_to(:parse_recursive)
  end
end
