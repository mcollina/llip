require File.dirname(__FILE__) + '/../spec_helper'

module RegexpMockScannerBuilder

  def mock_scanner(*tokens)
    @scanner = mock "Scanner"
    tokens.map! do |t|
      if t =~ /[\.\+\*\|\(\)\\\-\[\]]/
        Token.new(:symbol,t)
      else
        Token.new(:char,t)
      end
    end
    @tokens = tokens
    @tokens << nil unless tokens[-1].nil?
    t = nil
    @scanner.should_receive(:next).exactly(tokens.size).and_return { t = @tokens.shift }
    @scanner.should_receive(:current).any_number_of_times.and_return { t }
    Buffer.new(@scanner)
  end

end

describe "A RegexpParser should parse" do

  include RegexpMockScannerBuilder

  before(:each) do
    @parser = RegexpParser.new
    @parser.should respond_to(:parse)
  end

  it "'a'" do
    @scanner = mock_scanner('a')
    regexp = @parser.parse(@scanner)

    regexp.should_not be_nil
    regexp.should be_kind_of(RegexpSpecification)
    regexp.init.should_not be_nil
    regexp.init.should_not be_final
    regexp.init.should be_kind_of(RegexpSpecification::State)
    regexp.init['a'].should be_kind_of(RegexpSpecification::State)
    regexp.init['a'].final?.should == true
  end

  it "'abcde'" do
    @scanner = mock_scanner('a','b','c','d','e')
    regexp = @parser.parse(@scanner)

    lambda { regexp.init['a']['b']['c']['d']['e'].should be_final }.should_not raise_error
  end

  it "'a.bcde'" do
    @scanner = mock_scanner('a','.','b','c','d','e')
    regexp = @parser.parse(@scanner)

    lambda { regexp.init['a']['b']['c']['d']['e'].should be_final }.should_not raise_error
    lambda { regexp.init['a']['f']['b']['c']['d']['e'].should be_final }.should_not raise_error
    lambda { regexp.init['a']['f']['e'].should == :error }.should_not raise_error
		
    regexp.init['a']['b'].should be_kind_of(RegexpSpecification::State)
    regexp.init['a']['d']['b'].should == regexp.init['a']['b']
    regexp.init['a'].error.should be_kind_of(RegexpSpecification::State)
  end

  it "'a...bcde'" do
    @scanner = mock_scanner('a','.','.','.','b','c','d','e')
    regexp = @parser.parse(@scanner)

    regexp.init['a']['b']['c']['d']['e'].should be_final
    regexp.init['a']['f']['b']['c']['d']['e'].should be_final
    regexp.init['a']['f']['g']['b']['c']['d']['e'].should be_final
    regexp.init['a']['f']['g']['h']['i'].should == :error
    regexp.init['a']['f']['g']['h']['b']['c']['d']['e'].should be_final
		
    regexp.init['a']['b'].should be_kind_of(RegexpSpecification::State)
    regexp.init['a']['d']['b'].should == regexp.init['a']['b']
    regexp.init['a'].error.should be_kind_of(RegexpSpecification::State)
    regexp.init['a'].error.error.should be_kind_of(RegexpSpecification::State)
    regexp.init['a'].error.error.error.should be_kind_of(RegexpSpecification::State)
    regexp.init['a'].error.error.error['b'].should == regexp.init['a']['b']
  end

  it "'a\\.b'" do
    @scanner = mock_scanner('a','\\','.','b')
    regexp = @parser.parse(@scanner)
		
    regexp.init['a']['.']['b'].should be_final
  end

  it "'a\\nb" do
    @scanner = mock_scanner('a','\\','n','b')
    regexp = @parser.parse(@scanner)
		
    regexp.init['a']["\n"]['b'].should be_final
  end

  it "ab*c" do
    @scanner = mock_scanner('a','b','*','c')
    regexp = @parser.parse(@scanner)

    regexp.init['a']['c'].should be_final
    regexp.init['a']['b']['c'].should be_final
    regexp.init['a']['b']['b'].should == regexp.init['a']['b']
  end

  it "ab+c" do
    @scanner = mock_scanner('a','b','+','c')
    regexp = @parser.parse(@scanner)

    regexp.init['a']['c'].should == :error
    regexp.init['a']['b']['c'].should be_final
    regexp.init['a']['b']['b'].should == regexp.init['a']['b']
  end

  it "a.*c" do
    @scanner = mock_scanner('a','.','*','c')
    regexp = @parser.parse(@scanner)

    regexp.init['a']['c'].should be_final
    regexp.init['a']['e']['c'].should be_final
    regexp.init['a']['f']['e']['c'].should == regexp.init['a']['c']
    regexp.init['a'].error.error.should ==  regexp.init['a'].error
  end

  it "ac*" do
    @scanner = mock_scanner('a','c','*')
    regexp = @parser.parse(@scanner)

    regexp.init['a']['c'].should be_final
    regexp.init['a'].should be_final
    regexp.init['a']['c']['c'].should be_final
    regexp.init['a']['c']['c']['c'].should == regexp.init['a']['c']
  end


  it "a.+c" do
    @scanner = mock_scanner('a','.','+','c')
    regexp = @parser.parse(@scanner)

    regexp.init['a']['c'].should_not be_final
    regexp.init['a']['e']['c'].should be_final
    regexp.init['a']['f']['e']['c'].should == regexp.init['a']['b']['c']
    regexp.init['a'].error.error.error.should ==  regexp.init['a'].error.error
  end

  it "a|b|c" do
    @scanner = mock_scanner('a','|','b','|','c')
    regexp = @parser.parse(@scanner)

    regexp.init.keys.should == ['a','b','c']
    regexp.init.error.should == :error

    regexp.init['a'].should be_final
    regexp.init['b'].should be_final
    regexp.init['c'].should be_final
  end

  it "a(b|c)" do
    @scanner = mock_scanner("a","(","b","|","c",")")
    regexp = @parser.parse(@scanner)

    regexp.last.should == [regexp.init['a']['b'],regexp.init['a']['c']]

    regexp.init.keys.should == ['a']
    regexp.init['a'].keys.should == ['b','c']
    regexp.init['a']['b'].should be_final
    regexp.init['a']['c'].should be_final
    regexp.init['a']['b'].should == regexp.init['a']['c']
  end

  it "a(b|c)d" do
    @scanner = mock_scanner("a","(","b","|","c",")",'d')
    regexp = @parser.parse(@scanner)

    regexp.init['a'].keys.should == ['b','c']
    regexp.init['a']['b']['d'].should be_final
    regexp.init['a']['c']['d'].should be_final
		
    regexp.last.should == [regexp.init['a']['b']['d']]
  end

  it "..(b|c)" do
    @scanner = mock_scanner(".",".","(","b","|","c",")")
    regexp = @parser.parse(@scanner)

    regexp.last.should == [regexp.init.error.error['b'],regexp.error.error['c']]
		
    regexp.init.error.error.keys.should == ['b','c']
    regexp.init['a']['3']['b'].should be_final
    regexp.init['a']['f']['c'].should be_final
    regexp.init['e']['f']['b'].should == regexp.init['a']['h']['c']
		
    regexp.last.should == [regexp.init.error.error['b'],regexp.error.error['c']]
  end

  it "a(b|ce)*d" do
    @scanner = mock_scanner("a","(","b","|","c","e",")","*","d")
    regexp = @parser.parse(@scanner)

    regexp.init['a'].keys.should == ['b','c','d']
		
    regexp['a']['b'].keys.should == ['b','c','d']
    regexp['a']['c'].keys.should == ['e']
    regexp['a']['c']['e'].keys.should == ['b','c','d']
		
    regexp.init['a']['b']['d'].should be_final
    regexp.init['a']['c']['e']['d'].should be_final
    regexp.init['a']['d'].should be_final
	
    regexp.init['a'].should == regexp.init['a']['b']
    regexp.init['a']['b']['b'].should == regexp.init['a']['b']
    regexp.init['a'].should == regexp.init['a']['c']['e']
    regexp.init['a']['d'].should == regexp.init['a']['b']['d']
		
    regexp['a']['b'].final?.should == false
    regexp.init['a']['c'].final?.should == false
    regexp.init['a']['c']['e'].final?.should == false
  end

  it "a(b|ce)+d" do
    @scanner = mock_scanner("a","(","b","|","c","e",")","+","d")
    regexp = @parser.parse(@scanner)

    regexp.init['a'].keys.should == ['b','c']
		
    regexp['a']['b'].keys.should == ['b','c','d']
    regexp['a']['c'].keys.should == ['e']
    regexp['a']['c']['e'].keys.should == ['b','c','d']
		
    regexp.init['a']['b']['d'].should be_final
    regexp.init['a']['c']['e']['d'].should be_final
	
    regexp.init['a'].should_not == regexp.init['a']['b']
    regexp.init['a'].should_not == regexp.init['a']['c']['e']
		
    regexp.init['a']['b']['b'].should == regexp.init['a']['b']
    regexp.init['a']['c']['e'].should == regexp.init['a']['b']
    regexp.init['a']['c']['e']['c']['e'].should == regexp['a']['c']['e']

    regexp['a']['b'].final?.should == false
    regexp.init['a']['c'].final?.should == false
    regexp.init['a']['c']['e'].final?.should == false
  end
  
  it "[a-zD]" do
    @scanner = mock_scanner("[","a","-","z","D","]")
    regexp = @parser.parse(@scanner)
    
    keys = regexp.init.keys
    expected_keys = ("a".."z").to_a + ["D"]
    keys.sort!
    expected_keys.sort!
    keys.should == expected_keys
    keys.each do |key|
      regexp[key].should be_final
    end
  end
  
  it "[a-Z]" do
    @scanner = mock_scanner("[","a","-","Z","]")
    regexp = @parser.parse(@scanner)
    
    keys = regexp.init.keys
    expected_keys = ("a".."z").to_a + ("A".."Z").to_a
    keys.sort!
    expected_keys.sort!
    keys.should == expected_keys
    keys.each do |key|
      regexp[key].should be_final
    end
  end
  
  
  it "a[bc]+d" do
    @scanner = mock_scanner("a","[","b","c","]","+","d")
    regexp = @parser.parse(@scanner)

    regexp.init['a'].keys.should == ['b','c']
		
    regexp['a']['b'].keys.should == ['b','c','d']
    regexp['a']['c'].keys.should == ['b','c','d']
		
    regexp.init['a']['b']['d'].should be_final
    regexp.init['a']['c']['d'].should be_final
	
    regexp.init['a'].should_not == regexp.init['a']['b']
    regexp.init['a'].should_not == regexp.init['a']['c']
		
    regexp.init['a']['b']['b'].should == regexp.init['a']['b']
    regexp.init['a']['c']['b'].should == regexp.init['a']['b']
    regexp.init['a']['b']['c'].should == regexp['a']['c']

    regexp['a']['b'].final?.should == false
    regexp.init['a']['c'].final?.should == false
    regexp.init['a']['c'].final?.should == false
  end
  
    
  it "a[bc]*d" do
    @scanner = mock_scanner("a","[","b","c","]","*","d")
    regexp = @parser.parse(@scanner)

    regexp.init['a'].keys.should == ['b','c','d']
    regexp['a']['d'].should be_final
		
    regexp['a']['b'].keys.should == ['b','c','d']
    regexp['a']['c'].keys.should == ['b','c','d']
		
    regexp.init['a']['b']['d'].should be_final
    regexp.init['a']['c']['d'].should be_final
	
    regexp.init['a'].should == regexp.init['a']['b']
    regexp.init['a'].should == regexp.init['a']['c']
		
    regexp.init['a']['b']['b'].should == regexp.init['a']['b']
    regexp.init['a']['c']['b'].should == regexp.init['a']['b']
    regexp.init['a']['b']['c'].should == regexp['a']['c']

    regexp['a']['b'].final?.should == false
    regexp.init['a']['c'].final?.should == false
    regexp.init['a']['c'].final?.should == false
  end

end

describe "A RegexpParser should not parse" do

  include RegexpMockScannerBuilder

  before(:each) do
    @parser = RegexpParser.new
    @parser.should respond_to(:parse)
  end

  it "a(cdef" do
    @scanner = mock_scanner("a","(","b","c","d","e","f")
    lambda { @parser.parse(@scanner) }.should raise_error(RuntimeError)
  end
  
  it "a[cdef" do
    @scanner = mock_scanner("a","[","b","c","d","e","f")
    lambda { @parser.parse(@scanner) }.should raise_error(RuntimeError)
  end

end
