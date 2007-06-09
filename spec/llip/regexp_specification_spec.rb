require File.dirname(__FILE__) + '/../spec_helper'
require 'regexp_specification'

describe "A RegexpSpecification" do

  before(:each) do
    @instance = RegexpSpecification.new(:a_name)
  end

  it "should store the initialization parameter in the attribute name" do
    @instance.name.should == :a_name
  end

  it "should have an read-write attribute name and its default should be nil" do
    @instance.should respond_to(:name)
    @instance.should respond_to(:name=)

    @instance.name= :pippo
    @instance.name.should == :pippo
		
    lambda { @instance = RegexpSpecification.new }.should_not raise_error
    @instance.name.should be_nil
  end

  it "should send :to_sym to the initialization parameter" do
    m = mock("symbol")
    m.should_receive(:to_sym).and_return(:a_sym)
    @instance = RegexpSpecification.new(m)
    @instance.name.should == :a_sym
  end

  it "should have a states attribute which must be an hash" do
    @instance.should respond_to(:states)
    @instance.states.should == {}
  end

  it "should redirect its (:[],:[]=,:keys,:values,:each,:error,:error=,:final?,:final=) methods to the #init ones" do
    m = mock("State")
    m.should_receive(:name).and_return(:a_name)
    m.should_receive(:kind_of?).with(RegexpSpecification::State).and_return(true)
    m.should_receive(:[]).with(:a).and_return(:uh)
    m.should_receive(:[]=).with(:a,:buh).and_return(:buh)
    m.should_receive(:keys)
    m.should_receive(:values)
    m.should_receive(:each)
    m.should_receive(:error)
    m.should_receive(:error=)
    m.should_receive(:final=)
    m.should_receive(:final?)
    m.should_receive(:regexp=).with(@instance)
    @instance.add_state(m)

    @instance[:a].should == :uh
    (@instance[:a] = :buh).should == :buh

    lambda { 	
      @instance.keys
      @instance.values
      @instance.each
      @instance.error
      @instance.error=
      @instance.final=
      @instance.final?
    }.should_not raise_error
		
    2+2 # stupid hack because of stupid rcov
  end

  it "should have an :add_state method which add the value in the hash with a key that correspond at the value's name." do
    m = mock("State")
    m.should_receive(:name).and_return(1)
    m.should_receive(:kind_of?).with(RegexpSpecification::State).and_return(false)
    m.should_receive(:kind_of?).with(RegexpSpecification).and_return(true)
    m.should_receive(:regexp=).with(@instance)	
    @instance.should respond_to(:add_state)
    @instance.add_state(m).should == m
    @instance.states[1].should == m
  end

  it "should have an :add_state method which create a new State based on the hash passed as a parameter" do
    m = mock("hash")
    m.should_receive(:[]).with(:final).and_return(true)
    m.should_receive(:[]).with(:error).and_return(:self)
		
    result = @instance.add_state(m)
    result.should be_kind_of(RegexpSpecification::State)
    result.regexp.should == @instance

    lambda { @instance.add_state.should be_kind_of(RegexpSpecification::State) }.should_not raise_error
  end

  it "should have a :starting_chars method which returns the init State keys" do
    @instance.should respond_to(:starting_chars)
    @instance.starting_chars.should == []

    @instance.add_state["a"] = :try
    @instance.starting_chars.should == ["a"]
  end

  it "should have a :starting_chars method which returns :everything if the init State has an error which isn't a State" do
    @instance.add_state.error = @instance.add_state
    @instance.starting_chars.should == :everything
  end
end

describe "A RegexpSpecificatio should have a :last method which is able to discover the last State of" do
	
  before(:each) do
    @instance = RegexpSpecification.new
    @instance.should respond_to(:last)
    @instance.last.should == []
  end

  it "'abc'" do
    @a = @instance.add_state
    @b = @instance.add_state
    @c = @instance.add_state
    @d = @instance.add_state(:final => true)
    @a['a'] = @b
    @b['b'] = @c
    @c['c'] = @d

    @instance.last.should == [@d]
  end

  it "'a(b|cd)*'" do
    @a = @instance.add_state

    @b = @instance.add_state(:final => true)
		
    @c = @instance.add_state
		
    @a['a'] = @b
    @b['b'] = @b
    @b['c'] = @c
    @c['d'] = @b

    @instance.last.should == [@b]
  end

  it "'a(b|ce)*d'" do
    @a = @instance.add_state
    @b = @instance.add_state
    @c = @instance.add_state
    @d = @instance.add_state
    @e = @instance.add_state
    @g = @instance.add_state(:final => true)

    @a['a'] = @b
		
    @b['b'] = @d
    @b['c'] = @c
    @b['d'] = @g
		
    @d['b'] = @d
    @d['c'] = @c
    @d['d'] = @g

    @c['e'] = @e

    @e['b'] = @d
    @e['c'] = @c
    @e['d'] = @g

    @instance.last.should == [@g]
  end

  it "'a(b|cd)'" do
    @a = @instance.add_state
    @b = @instance.add_state
    @c = @instance.add_state
    @d = @instance.add_state(:final => true)

    @a['a'] = @b
    @b['b'] = @d
    @b['c'] = @c
    @c['d'] = @d

    @instance.last.should == [@d]
  end

  it "'a(.+|cd)b" do
    @a = @instance.add_state
    @f = @instance.add_state(:error => :self)
    @b = @instance.add_state(:error => @f)
    @c = @instance.add_state
    @d = @instance.add_state
    @e = @instance.add_state(:final => true)

    @a['a'] = @b
    @b['c'] = @c
    @c['d'] = @d
    @d['b'] = @e
    @f['b'] = @e	

    @instance.last.should == [@e]
  end

  it "'a.b'" do
    @a = @instance.add_state
    @c = @instance.add_state
    @b = @instance.add_state(:error => @c)
    @d = @instance.add_state(:final => true)
		
    @a['a'] = @b
    @c['b'] = @d

    @instance.last.should == [@d]
  end

  it "'a.*b'" do
    @a = @instance.add_state
    @c = @instance.add_state(:error => :self)
    @b = @instance.add_state(:error => @c)
    @d = @instance.add_state(:final => true)
		
    @a['a'] = @b
    @b['b'] = @d
    @c['b'] = @d

    @instance.last.should == [@d]
  end

  it "'ac*'" do
    @a = @instance.add_state
    @b = @instance.add_state(:final => true)
		
    @a['c'] = @b
    @b['c'] = @b

    @instance.last.should == [@b]
  end

  it "'a.'" do
    @a = @instance.add_state
    @c = @instance.add_state(:final => true)
    @b = @instance.add_state(:error => @c)

    @a['a'] = @b

    @instance.last.should == [@c]
  end

  it "'.a'" do
    @a = @instance.add_state
    @b = @instance.add_state
    @c = @instance.add_state(:final => true)
    @a.error = @b
    @b['a'] = @c

    @instance.last.should == [@c]
  end

  it "'..a'" do
    @a = @instance.add_state
    @b = @instance.add_state
    @c = @instance.add_state
    @d = @instance.add_state(:final => true)
    @a.error = @b
    @b.error = @c
    @c['a'] = @d

    @instance.last.should == [@d]
  end

end

describe "A RegexpSpecification::State" do
	
  before(:each) do
    @instance = RegexpSpecification::State.new
  end

  it "should be a kind of hash" do
    @instance.should be_kind_of(Hash)
  end

  it "should return :error if it's requested an unknown key" do
    @instance[:unknown_key].should == :error
  end

  it "should admit to specify the error code" do
    m = mock("sym")
    m.should_receive(:to_sym).and_return(:a_different_error_code)
    m.should_receive(:respond_to?).with(:to_sym).and_return(true)
    @instance = RegexpSpecification::State.new(:error => m) 
    @instance[:unknown_key].should == :a_different_error_code
  end

  it "should set the error code to its name if the error code specified is :self" do
    @instance = RegexpSpecification::State.new(:error => :self) 
    @instance[:unknown_key].should == @instance
  end

  it "should have a name which is a Numeric identifier" do
    @instance.should respond_to(:name)
    @instance.name.should_not be_nil
    @instance.name.should be_kind_of(Numeric)

    second = RegexpSpecification::State.new
    second.name.should > @instance.name
  end

  it "should have a :final? method which is initialized by an hash-like initialization argument" do
    @instance.should respond_to(:final?)
    @instance.final?.should == false

    lambda { @instance = RegexpSpecification::State.new(:final => true) }.should_not raise_error
    @instance.final?.should == true
  end

  it "should have a :final= method which sets :final" do
    @instance.should respond_to(:final=)
    @instance.final= true
    @instance.should be_final
  end

  it "should have as hash the hash of its name" do
    @instance.hash.should == @instance.name.hash
  end

  it "should allow to set the error code through :error=" do
    @instance.should respond_to(:error)
    @instance.should respond_to(:error=)
    @instance.error.should == @instance.default
    @instance.error= :ghgh
    @instance.error.should == :ghgh
    @instance.error.should == @instance.default
    @instance["huhu"].should == :ghgh
  end

  it "should not be equal to another State with same content but different error" do
    @another = RegexpSpecification::State.new
    @instance.error = RegexpSpecification::State.new
		
    @instance.should_not == @another

    @another.error = RegexpSpecification::State.new

    @instance.should == @another
		
    @another.error['p'] = :pluto
		
    @instance.should_not == @another

    @another.error = @instance.error
    @instance.should == @another
  end

  it "should memorize its regexp internally" do
    @instance.should respond_to(:regexp)
    @instance.should respond_to(:regexp=)
    @instance.regexp.should be_nil
    @instance.regexp = :regexp
    @instance.regexp.should == :regexp
  end
end

describe "A RegexpSpecification should be able to represent" do
	
  before(:each) do
    @instance = RegexpSpecification.new(:a_regexp)
    @state = RegexpSpecification::State
  end

  it "'abc'" do
    @a = @instance.add_state
    @b = @instance.add_state
    @c = @instance.add_state
    @d = @instance.add_state(:final => true)
    @a['a'] = @b
    @b['b'] = @c
    @c['c'] = @d

    scan(["a","b","c"]).should == true
    scan(["a","b","c","d"]).should == false
  end

  it "'a.b'" do
    @a = @instance.add_state
    @c = @instance.add_state
    @b = @instance.add_state(:error => @c)
    @d = @instance.add_state(:final => true)
		
    @a['a'] = @b
    @c['b'] = @d

    scan(["a","b"]).should == false
    scan(["a","c","b"]).should == true
    scan(["a","c","d"]).should == false
    scan(["a","c","d","b"]).should == false
  end

  it "'a.+b'" do
    @a = @instance.add_state
    @c = @instance.add_state(:error => :self)
    @b = @instance.add_state(:error => @c)
    @d = @instance.add_state(:final => true)
		
    @a['a'] = @b
    @c['b'] = @d

    scan(["a","b"]).should == false
    scan(["a","c","b"]).should == true
    scan(["a","c","d"]).should == false
    scan(["a","c","d","b"]).should == true
  end
	
  it "'a.*b'" do
    @a = @instance.add_state
    @c = @instance.add_state(:error => :self)
    @b = @instance.add_state(:error => @c)
    @d = @instance.add_state(:final => true)
		
    @a['a'] = @b
    @b['b'] = @d
    @c['b'] = @d

    scan(["a","b"]).should == true
    scan(["a","c","b"]).should == true
    scan(["a","c","d"]).should == false
    scan(["a","c","d","b"]).should == true
  end
	
  it "'a(b|cd)'" do
    @a = @instance.add_state
    @b = @instance.add_state
    @c = @instance.add_state
    @d = @instance.add_state(:final => true)

    @a['a'] = @b
    @b['b'] = @d
    @b['c'] = @c
    @c['d'] = @d

    scan(["a","b"]).should == true
    scan(["a","c","d"]).should == true
    scan(["a","b","c","d"]).should == false
  end

  it "'a(b|cd)*'" do
    @a = @instance.add_state

    @b = @instance.add_state(:final => true)

    @c = @instance.add_state

    @a['a'] = @b
    @b['b'] = @b
    @b['c'] = @c
    @c['d'] = @b
		

    scan(["a"]).should == true
    scan(["a","b"]).should == true
    scan(["a","c","d"]).should == true
    scan(["a","b","c","d"]).should == true
    scan(["a","b","c","e"]).should == false
    scan(["a","b","c","d","b"]).should == true
  end

  it "'a(b|cd)+'" do
    @a = @instance.add_state
    @b = @instance.add_state
    @c = @instance.add_state
    @d = @instance.add_state(:final => true)

    @e = @instance.add_state
    @f = @instance.add_state

    @a['a'] = @b
    @b['b'] = @d
    @b['c'] = @c
    @c['d'] = @d
	
    @d['b'] = @d
    @d['c'] = @e
    @e['d'] = @d	

    scan(["a","b"]).should == true
    scan(["a","c","d"]).should == true
    scan(["a","b","c","d"]).should == true
    scan(["a","b","c","d","b"]).should == true
  end

  it "'a(.+|cd)b" do
    @a = @instance.add_state
    @f = @instance.add_state(:error => :self)
    @b = @instance.add_state(:error => @f)
    @c = @instance.add_state
    @d = @instance.add_state
    @e = @instance.add_state(:final => true)

    @a['a'] = @b
    @b['c'] = @c
    @c['d'] = @d
    @d['b'] = @e
    @f['b'] = @e	


    scan(["a","c","d","b"]).should == true
    scan(["a","b","b"]).should == true
    scan(["a","e","f","b"]).should == true
  end

  it "'a(b|ce)*d'" do
    @a = @instance.add_state
    @b = @instance.add_state
    @c = @instance.add_state
    @d = @instance.add_state
    @e = @instance.add_state
    @g = @instance.add_state(:final => true)

    @a['a'] = @b
		
    @b['b'] = @d
    @b['c'] = @c
    @b['d'] = @g
		
    @d['b'] = @d
    @d['c'] = @c
    @d['d'] = @g

    @c['e'] = @e

    @e['b'] = @d
    @e['c'] = @c
    @e['d'] = @g

    scan("a","d").should == true	
    scan("a",'b',"d").should == true	
    scan("a","b","b","d").should == true	
    scan("a","b","b","b","c","e","b","d").should == true	
    scan("a","b","c","e","b","c","e","b","d").should == true	
    scan("a","b","c","e","b","c","e","b").should == false	
  end

  def scan(*chars)
    chars.flatten!
    next_state = @instance.init
    chars.each do |c|
      next_state = next_state[c]
      return false if next_state == :error
    end
    next_state.final?
  end
end

describe "The :mix method of the RegexpSpecification class" do
	
  before(:each) do
    RegexpSpecification.should respond_to(:mix)
  end

  it "should be able to mix: 'ab' and 'ac'" do
    r1 = RegexpSpecification.new("first")
    r2 = RegexpSpecification.new("second")
		
    s1 = r1.add_state
    s2 = r1.add_state
    s3 = r1.add_state(:final => true)
    s1['a'] = s2
    s2['b'] = s3

    s4 = r2.add_state
    s5 = r2.add_state
    s6 = r2.add_state(:final => true)
    s4['a'] = s5
    s5['c'] = s6
		
    result = RegexpSpecification.mix(r1,r2)
    result.name.should == :"mix between 'first' and 'second'"
    second = result['a']
    second.should_not == :error
    second['b'].should == s3
    second['c'].should == s6
  end
	
  it "should be able to mix: '.b' and '.c'" do
    r1 = RegexpSpecification.new("first")
    r2 = RegexpSpecification.new("second")
		
    s1 = r1.add_state
    s2 = r1.add_state
    s3 = r1.add_state(:final => true)
    s1.error =  s2
    s2['b'] = s3

    s4 = r2.add_state
    s5 = r2.add_state
    s6 = r2.add_state(:final => true)
    s4.error = s5
    s5['c'] = s6
		
    result = RegexpSpecification.mix(r1,r2)
    result.name.should == :"mix between 'first' and 'second'"
    second = result.init.error
    second.should_not == :error
    second['b'].should == s3
    second['c'].should == s6
  end
	
  it "should be able to mix: 'a.b' and 'ac'" do
    r1 = RegexpSpecification.new("first")
    r2 = RegexpSpecification.new("second")
		
    s1 = r1.add_state
    s2 = r1.add_state
    s3 = r1.add_state
    s4 = r1.add_state(:final => true)
    s1['a'] = s2
    s2.error =  s3
    s3['b'] = s4

    s4 = r2.add_state
    s5 = r2.add_state
    s6 = r2.add_state(:final => true)
    s4['a'] = s5
    s5['c'] = s6
		
    result = RegexpSpecification.mix(r1,r2)
    result.name.should == :"mix between 'first' and 'second'"
    second = result.init
    second.should_not == :error
    second['a'].should_not == :error
    second['a']['c'].should == s6
    second['a'].error.should_not == :error
    second['a'].error.should == s3

    result = RegexpSpecification.mix(r2,r1)
    result.name.should == :"mix between 'second' and 'first'"
    second = result.init
    second.should_not == :error
    second['a'].should_not == :error
    second['a']['c'].should == s6
    second['a'].error.should_not == :error
    second['a'].error.should == s3
  end

  it "should raise if trying to mix: 'ab' and 'abc'" do
    r1 = RegexpSpecification.new("first")
    r2 = RegexpSpecification.new("second")
		
    s1 = r1.add_state
    s2 = r1.add_state
    s3 = r1.add_state(:final => true)
    s1['a'] = s2
    s2['b'] = s3

    s4 = r2.add_state
    s5 = r2.add_state
    s6 = r2.add_state
    s7 = r2.add_state(:final => true)
    s4['a'] = s5
    s5['b'] = s6
    s6['c'] = s7
		
    lambda { RegexpSpecification.mix(r1,r2) }.should raise_error(RuntimeError)
  end

  it "should be able to mix: '(a|b)c' and '(b|e)d'" do
    r1 = RegexpSpecification.new("first")
    r2 = RegexpSpecification.new("second")

    s1 = r1.add_state
    s2 = r1.add_state
    s3 = r1.add_state(:final => true)
    s4 = r1.add_state
		
    s1['a'] = s2
    s2['c'] = s3
    s1['b'] = s4
    s4['c'] = s3

    s5 = r2.add_state
    s6 = r2.add_state
    s7 = r2.add_state(:final => true)
    s8 = r2.add_state
		
    s5['e'] = s6
    s6['d'] = s7
    s5['b'] = s8
    s8['d'] = s7
		
    result = RegexpSpecification.mix(r1,r2)
    result.name.should == :"mix between 'first' and 'second'"
    result['a'].should == s2
    result['e'].should == s6
    result['b'].should_not == :error
    result['b']['c'].should == s3
    result['b']['d'].should == s7
  end

  it "should be able to mix: '(a|b)+c' and '(b|e)+d'" do
    r1 = RegexpSpecification.new("first")
    r2 = RegexpSpecification.new("second")

    s1 = r1.add_state
    s2 = r1.add_state
    s3 = r1.add_state(:final => true)
		
    s1['a'] = s2
    s1['b'] = s2
    s2['a'] = s2
    s2['b'] = s2
    s2['c'] = s3

    s4 = r2.add_state
    s5 = r2.add_state
    s6 = r2.add_state(:final => true)
		
    s4['e'] = s5
    s4['b'] = s5
    s5['e'] = s5
    s5['b'] = s5
    s5['d'] = s6
		
    result = RegexpSpecification.mix(r1,r2)
    result.name.should == :"mix between 'first' and 'second'"
    result['a'].should == s2
    result['e'].should == s5
    result['b'].should_not == :error
    result['b'].should_not == s2	
    result['b'].should_not == s5
    result['b']['b'].should_not == :error
    result['b']['b'].should == result['b']['b']['b']
    result['b']['a'].should == s2	
    result['b']['e'].should == s5
    result['b']['b'].should_not == s2
    result['b']['b'].should_not == s5
    result['b']['b']['a'].should == s2
    result['b']['b']['e'].should == s5
  end
end
