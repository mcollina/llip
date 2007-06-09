require File.dirname(__FILE__) + '/../spec_helper'
require 'buffer'

describe "A Buffer" do
	
  before(:each) do
    @scanner = mock 'Scanner'
    @buf = Buffer.new(@scanner)
  end

  it "should wrap a scanner" do
    @buf.should respond_to(:scanner)
    @buf.should respond_to(:scanner=)

    @buf.scanner.should == @scanner

    @buf.scanner = nil
    @buf.scanner.should be_nil
  end

  it "should have a next method, which calls the scanner's next method" do
    @buf.should respond_to(:next)
    @scanner.should_receive(:next).and_return(:token)
    @buf.next.should == :token
  end

  it "should have a scan method, which calls the scanner's scan method" do
    @buf.should respond_to(:scan)
    @scanner.should_receive(:scan).with("a string")
    @buf.scan("a string").should == @buf
  end

  it "should have a current method, which returns the last token read" do
    @buf.should respond_to(:current)
    @scanner.should_receive(:next).and_return(:token)
    @buf.next
    @buf.current.should == :token
  end

  it "should allow lookahead" do
    @buf.should respond_to(:lookahead)
    @scanner.should_receive(:next).and_return(:first,:second,:third,nil)
    @buf.next
    @buf.current.should == :first

    @buf.lookahead(1).should == :second
    @buf.current.should == :first

    @buf.lookahead(2).should == :third
    @buf.lookahead(1).should == :second
    @buf.current.should == :first
	
    @buf.next

    @buf.lookahead(2).should be_nil
    @buf.lookahead(1).should == :third
    @buf.current.should == :second
  end	
end

