require File.dirname(__FILE__) + '/../spec_helper'
require 'stringio'

describe "A RegexpScanner should scan" do

  before(:each) do
    @scanner = RegexpScanner.new
  end

  it "'abc'" do
    lambda { @scanner.scan('abc') }.should_not raise_error
    token = @scanner.next
    token.should == 'a'
    token.should == :char
    @scanner.next.should == 'b'
    @scanner.next.should == 'c'
  end

  it "'.*abc'"do
    @scanner.scan('.*abc(d|e)+\\.')
    token = @scanner.next
    token.should == '.'
    token.should == :symbol
    @scanner.next.should == :symbol
    @scanner.next.should == 'a'
    @scanner.next.should == 'b'
    @scanner.next.should == 'c'
    @scanner.next.should == :symbol
    @scanner.next.should == 'd'
    @scanner.next.should == :symbol
    @scanner.next.should == 'e'
    @scanner.next.should == :symbol
    @scanner.next.should == :symbol
    @scanner.next.should == :symbol
    @scanner.next.should == :symbol
    @scanner.next.should be_nil
  end
  
  it "'[a-zA-Z]'" do
    @scanner.scan('[a-zA-Z]')
    @scanner.next.should == :symbol
    @scanner.next.should == 'a'
    @scanner.next.should == '-'
    @scanner.next.should == 'z'
    @scanner.next.should == 'A'
    @scanner.next.should == '-'
    @scanner.next.should == 'Z'
    @scanner.next.should == :symbol
  end
end
