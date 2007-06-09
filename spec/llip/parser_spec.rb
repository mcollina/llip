require File.dirname(__FILE__) + '/../spec_helper'
require 'parser'
require 'stringio'

describe "A class that descend from Parser" do
  before(:each) do
    @class = Class.new(Parser)
  end

  it "should have an attribute parser which descends from AbstractParser"  do
    @class.should respond_to(:parser)
    @class.parser.should be_kind_of(Class)
    @class.parser.ancestors[1].should == AbstractParser
  end

  it "should have an attribute scanner which descends from RegexpAbstractScanner"  do
    @class.should respond_to(:scanner)
    @class.scanner.should be_kind_of(Class)
    @class.scanner.ancestors[1].should == RegexpAbstractScanner
  end

  it "should redirect :production, :scope to the parser" do
    @class.should respond_to(:production)
    @class.should respond_to(:scope)
		
    m = mock("parser")
    m.should_receive(:production).and_return(:prod)
    m.should_receive(:scope).and_return(:scop)

    @class.instance_variable_set(:@parser,m)
		
    @class.production
    @class.scope
  end

  it "should have a :regexp_parser and :regexp_scanner attributes" do
    @class.should respond_to(:regexp_parser)
    @class.should respond_to(:regexp_scanner)

    @class.regexp_parser.should be_kind_of(RegexpParser)
    @class.regexp_scanner.should be_kind_of(RegexpScanner)
  end

  it "should have a token method which parse a regexp and calls :add_regexp to the scanner" do

    @class.should respond_to(:token)

    rs = mock("regexp_scanner")
    rs.should_receive(:scan).with("a regexp").and_return(rs)

    regexp = mock("regexp")
    regexp.should_receive(:name=).with(:a_name)

    rp = mock("regexp_parser")
    rp.should_receive(:parse).with(rs).and_return(regexp)

    m = mock("scanner")
    m.should_receive(:add_regexp).with(regexp)

    @class.instance_variable_set(:@regexp_scanner,rs)
    @class.instance_variable_set(:@regexp_parser,rp)
		
    @class.instance_variable_set(:@scanner,m)
    @class.token(:a_name,"a regexp")
  end

  it "should have a lookahead method which allow to set the lookahead behaviour" do
    @class.should respond_to(:lookahead)
    @class.lookahead.should == false
    @class.lookahead(true)
    @class.lookahead.should == true
  end

end

describe "The instance of a class desceding from Parser" do

  before(:each) do
    @class = Class.new(Parser)
    @instance = @class.new
  end

  it "should have a parser which must be kind of its class parser" do
    @instance.should respond_to(:parser)
    @instance.parser.should be_kind_of(@class.parser)
  end

  it "should have a scanner which must be kind of its class scanner" do
    @instance.should respond_to(:scanner)
    @instance.scanner.should be_kind_of(@class.scanner)
  end

  it "with lookahead(true) should have a buffer encapsuling the scanner instead of the scanner" do
    @class.lookahead(true)
    @instance = @class.new
		
    @instance.scanner.should be_kind_of(Buffer)
    s = mock("scanner")
    s.should_receive(:scan).with("a string").and_return(s)

    @instance.scanner.scanner= s

    result = mock("result")
		
    p = mock("parser")
    p.should_receive(:parse).with(@instance.scanner).and_return(result)
	
    @instance.instance_variable_set(:@parser,p)

    @instance.parse("a string")
  end

  it "should have a :parse method which accept a source and parse thrugh the parser and the scanner" do
    @instance.should respond_to(:parse)

    s = mock("scanner")
    s.should_receive(:scan).with("a string").and_return(s)

    result = mock("result")

    p = mock("parser")
    p.should_receive(:parse).with(s).and_return(result)

    @instance.instance_variable_set(:@scanner,s)
    @instance.instance_variable_set(:@parser,p)

    @instance.parse("a string").should == result
  end
end

describe "The instance of a class descending from Parser with a simple grammar should be able to parse" do
	
  before(:each) do
    @class = Class.new(Parser)
    @instance = @class.new

    @class.token(:plus,"\\+")
    @class.token(:number,("0".."9").to_a.join("|"))
	
    @class.scope(:exp)

    @class.production(:exp,:recursive) do |p|
      p.default { |scanner,parser| parser.parse_num }
		
      p.token(:plus) do |result,scanner,parser| 
        scanner.next
        result + parser.parse_num
      end
    end

    @class.production(:num,:single) do |p| 
      p.token(:number) do |result,scanner,parser|
        result = scanner.current.value.to_i
        scanner.next
        result
      end
    end
  end

  it "'1+1'" do
    @instance.parse("1+1").should == 2
  end
end
