require File.dirname(__FILE__) + '/../spec_helper'

describe "A class descending from RegexpAbstractScanner" do

  before(:each) do
    @class = Class.new(RegexpAbstractScanner)
    @scanner = @class.new
    @class.should_receive(:build).any_number_of_times
  end

  it "should respond to next and return Token.new if it isn't scanning a string" do
    @scanner.should respond_to(:next)
    @scanner.next.should be_kind_of(Token)
    @scanner.next.should be_nil
  end

  it "should allow to add some regexp adding them to its scanning table" do
    @class.should respond_to(:add_regexp)
    r = mock "regexp"
    r.should_receive(:starting_chars).and_return(["a","b"])
    lambda { @class.add_regexp(r) }.should_not raise_error
    @class.scanning_table['a'].should == r	
    @class.scanning_table['b'].should == r

    r2 = mock "regexp2"
    r2.should_receive(:starting_chars).and_return(["c","d"])	
    @class.add_regexp(r2)
    @class.scanning_table['c'].should == r2	
    @class.scanning_table['d'].should == r2
  end

  it "should handle correctly if two regexp ('ab', 'ac') have some starting chars in common" do
    r1 = mock "regexp1"
    s1 = mock "state1"
    s2 = mock "state2"
    s3 = mock "state3"
    r1.should_receive(:starting_chars).any_number_of_times.and_return(["a"])
    r1.should_receive(:name).any_number_of_times.and_return("r1")
    r1.should_receive(:init).any_number_of_times.and_return(s1)
    s1.should_receive(:keys).any_number_of_times.and_return(["a"])
    s1.should_receive(:[]).any_number_of_times.with("a").and_return(s2)
    s1.should_receive(:final?).any_number_of_times.and_return(false)
    s2.should_receive(:keys).any_number_of_times.and_return(['b'])
    s2.should_receive(:[]).with('b').and_return(s3)
    s2.should_receive(:final?).any_number_of_times.and_return(false)
    s3.should_receive(:keys).any_number_of_times.and_return([])
    s3.should_receive(:final?).any_number_of_times.and_return(true)
    s1.should_receive(:error).any_number_of_times.and_return(:error)
    s2.should_receive(:error).any_number_of_times.and_return(:error)
    s3.should_receive(:error).any_number_of_times.and_return(:error)
    s1.should_receive(:regexp).any_number_of_times.and_return(r1)
    s2.should_receive(:regexp).any_number_of_times.and_return(r1)
    s3.should_receive(:regexp).any_number_of_times.and_return(r1)

    r2 = mock "regexp2"
    s4 = mock "state4"
    s5 = mock "state5"
    s6 = mock "state6"
    r2.should_receive(:starting_chars).any_number_of_times.and_return(["a"])
    r2.should_receive(:name).any_number_of_times.and_return("r2")
    r2.should_receive(:init).any_number_of_times.and_return(s4)
    s4.should_receive(:keys).any_number_of_times.and_return(["a"])
    s4.should_receive(:[]).any_number_of_times.with("a").and_return(s5)
    s4.should_receive(:final?).any_number_of_times.and_return(false)
    s5.should_receive(:keys).any_number_of_times.and_return(['c'])
    s5.should_receive(:[]).with('c').and_return(s6)
    s5.should_receive(:final?).any_number_of_times.and_return(false)
    s6.should_receive(:keys).any_number_of_times.and_return([])
    s6.should_receive(:final?).any_number_of_times.and_return(true)
    s4.should_receive(:error).any_number_of_times.and_return(:error)
    s5.should_receive(:error).any_number_of_times.and_return(:error)
    s6.should_receive(:error).any_number_of_times.and_return(:error)
    s4.should_receive(:regexp).any_number_of_times.and_return(r2)
    s5.should_receive(:regexp).any_number_of_times.and_return(r2)
    s6.should_receive(:regexp).any_number_of_times.and_return(r2)
		
    @class.add_regexp(r1)
    lambda { @class.add_regexp(r2) }.should_not raise_error
    @class.scanning_table['a'].should be_kind_of(RegexpSpecification)
    init = @class.scanning_table['a'].init
    second = init['a']
    second.keys.should == ['b','c']
    second['b'].should == s3
    second['c'].should == s6
  end

  it "should set the default value of the scanning table to the regexp that have starting_chars == :everything" do
    r = mock "regexp"
    r.should_receive(:starting_chars).and_return(:everything)
    lambda { @class.add_regexp(r) }.should_not raise_error
    lambda { @class.scanning_table['a'].should == r }.should_not raise_error
  end

  it "should expose its scanning table" do
    @class.should respond_to(:scanning_table)
    @class.scanning_table.should be_kind_of(Hash)
    lambda { @class.scanning_table['a'] }.should_not raise_error
  end

  it "should be able to scan a simple regexp" do
    r = mock "regexp"
    s1 = mock "state1"
    s2 = mock "state"
    r.should_receive(:init).and_return(s1)
    r.should_receive(:starting_chars).and_return(["a"])
    r.should_receive(:name).and_return(:a_name)
    s1.should_receive(:[]).twice.with('a').and_return(s2)
    s2.should_receive(:[]).and_return(:error)
    s2.should_receive(:final?).and_return(true)
    s2.should_receive(:regexp).and_return(r)

    @class.add_regexp(r)
    @scanner.scan("a")
    token = @scanner.next
    token.should be_kind_of(Token)
    token.should == "a"
    token.should == :a_name
    token.line.should == 0
    token.char.should == 0
		
    @scanner.scan("b")
    lambda { @scanner.next }.should raise_error(LLIPError)
  end

  it "should be able to scan '.*b' and 'eb' " do
    r1 = mock "first"
    s1 = mock "state1"
    s2 = mock "state2"
    r1.should_receive(:init).any_number_of_times.and_return(s1)
    r1.should_receive(:starting_chars).and_return(:everything)
    r1.should_receive(:name).any_number_of_times.and_return(:first_name)
    s1.should_receive(:[]).any_number_of_times.with('b').and_return(s2)
    s1.should_receive(:[]).any_number_of_times.and_return(s1)
    s1.should_receive(:final?).and_return(false)
    s2.should_receive(:[]).any_number_of_times.and_return(:error)
    s2.should_receive(:final?).any_number_of_times.and_return(true)
    s1.should_receive(:regexp).any_number_of_times.and_return(r1)
    s2.should_receive(:regexp).any_number_of_times.and_return(r1)

    r2 = mock "second"
    s3 = mock "state3"
    s4 = mock "state4"
    s5 = mock "state5"
    r2.should_receive(:init).any_number_of_times.and_return(s3)
    r2.should_receive(:starting_chars).and_return(["e"])
    r2.should_receive(:name).any_number_of_times.and_return(:second_name)
    s3.should_receive(:[]).any_number_of_times.with('e').and_return(s4)
    s3.should_receive(:final?).any_number_of_times.and_return(false)
    s4.should_receive(:[]).any_number_of_times.with('b').and_return(s5)
    s5.should_receive(:[]).any_number_of_times.and_return(:error)
    s5.should_receive(:final?).any_number_of_times.and_return(true)
    s3.should_receive(:regexp).any_number_of_times.and_return(r2)
    s4.should_receive(:regexp).any_number_of_times.and_return(r2)
    s5.should_receive(:regexp).any_number_of_times.and_return(r2)
		
    @class.add_regexp(r1)
    @class.add_regexp(r2)

    @scanner.scan("acdb \nb abd")
    @scanner.next.should == "acdb"
    @scanner.current.char == 0
    @scanner.current.line == 0
    @scanner.current.name == :first_name

    @scanner.current.should == "acdb"	
    @scanner.next.should == " \nb"
    @scanner.current.char == 4
    @scanner.current.line == 0
    @scanner.next.should == " ab"
    @scanner.current.line == 1
    @scanner.current.char == 0
    lambda { @scanner.next }.should raise_error(UnvalidTokenError)
		
    @scanner.scan("b")
    @scanner.next
    token = @scanner.next
    token.should be_nil
    token.line.should == 2

    @scanner.scan("eb")
    token = @scanner.next
    token.should == "eb"
    token.name.should == :second_name
  end


  it "should be able to scan '\+ *'" do
    r = mock "regexp"
    s1 = mock "state1"
    s2 = mock "state"
    r.should_receive(:init).any_number_of_times.and_return(s1)
    r.should_receive(:starting_chars).and_return(['+'])
    r.should_receive(:name).any_number_of_times.and_return(:a_name)
    s1.should_receive(:[]).any_number_of_times.with('+').and_return(s2)
    s2.should_receive(:[]).any_number_of_times.with(' ').and_return(s2)
    s2.should_receive(:[]).any_number_of_times.and_return(:error)
    s2.should_receive(:final?).any_number_of_times.and_return(true)
    s1.should_receive(:regexp).any_number_of_times.and_return(r)
    s2.should_receive(:regexp).any_number_of_times.and_return(r)

    @class.add_regexp(r)
    @scanner.scan("+")
    @scanner.next.should == "+"
    @scanner.current.should == "+"	
    @scanner.next.should be_nil
		
    @scanner.scan("+ ")
    @scanner.next.should == "+ "		
    @scanner.current.should == "+ "	
    @scanner.next.should be_nil
	
    @scanner.scan("+    ")
    @scanner.next.should == "+    "		
    @scanner.current.should == "+    "	
    @scanner.next.should be_nil
  end

end

describe "A class descending from RegexpAbstractScanner with the build method exposed" do
	
  before(:each) do
    @class = Class.new(RegexpAbstractScanner)
  end

  it "should be able to scan '.+' and 'eb' " do
    r1 = mock "first"
    s1 = mock "state1"
    r1.should_receive(:init).any_number_of_times.and_return(s1)
    r1.should_receive(:starting_chars).and_return(:everything)
    r1.should_receive(:name).any_number_of_times.and_return(:first_name)
    r1.should_receive(:last).any_number_of_times.and_return([s1])
    s1.should_receive(:[]=).with("e",:error)
    s1.should_receive(:[]).with("e").and_return(:error)
    s1.should_receive(:[]).any_number_of_times.and_return(s1)
    s1.should_receive(:final?).any_number_of_times.and_return(true)
    s1.should_receive(:error).any_number_of_times.and_return(s1)
    s1.should_receive(:regexp).any_number_of_times.and_return(r1)

    r2 = mock "second"
    s3 = mock "state3"
    s4 = mock "state4"
    s5 = mock "state5"
    r2.should_receive(:init).any_number_of_times.and_return(s3)
    r2.should_receive(:starting_chars).and_return(["e"])
    r2.should_receive(:name).any_number_of_times.and_return(:second_name)
    r2.should_receive(:last).any_number_of_times.and_return([s5])
    s3.should_receive(:[]).any_number_of_times.with('e').and_return(s4)
    s3.should_receive(:final?).any_number_of_times.and_return(false)
    s4.should_receive(:[]).any_number_of_times.with('b').and_return(s5)
    s5.should_receive(:[]).any_number_of_times.and_return(:error)
    s5.should_receive(:final?).any_number_of_times.and_return(true)
    s5.should_receive(:error).any_number_of_times.and_return(nil)
    s3.should_receive(:regexp).any_number_of_times.and_return(r2)
    s4.should_receive(:regexp).any_number_of_times.and_return(r2)
    s5.should_receive(:regexp).any_number_of_times.and_return(r2)

    @class.add_regexp(r1)
    @class.add_regexp(r2)
		
    @scanner = @class.new
		
    @scanner.scan("acdb \nb abd")
    token = @scanner.next
    token.should == "acdb \nb abd"

    @scanner.scan("aeb")
    token = @scanner.next
    token.should == "a"
    token.name.should == :first_name
    token = @scanner.next
    token.should == "eb"
    token.name.should == :second_name

    @scanner.scan("eb")
    token = @scanner.next
    token.should == "eb"
    token.name.should == :second_name
  end

  it "should recall the build method if a new regexp is added and the scanner has already been built" do
    @class.built?.should == false
    @scanner = @class.new
    @class.built?.should == true
    @class.should_receive(:build)
    r = mock "regexp"
    r.should_receive(:starting_chars).and_return(["a"])
    @class.add_regexp(r)
  end

  it "should have a build method which sets :error for every final state which ends with '.*' or '.+'" do
    @class.should respond_to(:build)
    @class.should respond_to(:built?)

    r1 = mock "normal"
    s1 = mock "state1"
    s2 = mock "state2"
    r1.should_receive(:init).any_number_of_times.and_return(s1)
    r1.should_receive(:starting_chars).and_return(["a"])
    r1.should_receive(:last).and_return([s2])
    s2.should_receive(:error).any_number_of_times.and_return(:error)

    r2 = mock "everything"
    s3 = mock "state3"
    r2.should_receive(:init).any_number_of_times.and_return(s3)
    r2.should_receive(:starting_chars).and_return(:everything)
    r2.should_receive(:last).and_return([s3])
    s3.should_receive(:error).any_number_of_times.and_return(s3)
    s3.should_receive(:[]=).with("a",:error)

    @class.add_regexp(r1)
    @class.add_regexp(r2)
		
    @class.built?.should == false
		
    @class.build.should == @class
    @class.built?.should == true
  end
end
