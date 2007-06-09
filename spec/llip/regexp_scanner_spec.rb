require File.dirname(__FILE__) + '/../spec_helper'
require 'regexp_scanner'
require 'token'
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
end
