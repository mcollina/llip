require File.dirname(__FILE__) + '/../spec_helper'
require 'abstract_scanner'
require 'stringio'

describe "An AbstractScanner" do

  before(:each) do
    @instance = AbstractScanner.new
  end

  it "should be able to scan a string" do
    @instance.should respond_to(:scan)
    @instance.should_receive(:read_next).once
    lambda { @instance.scan("this is a string") }.should_not raise_error
    @instance.source.should be_kind_of(StringIO)	
    @instance.source.string.should == "this is a string"
  end

  it "should be able to scan an IO" do
    @instance.should respond_to(:scan)
    @instance.should_receive(:read_next).once
    io = StringIO.new("this is a string")
    lambda { @instance.scan(io) }.should_not raise_error
    @instance.source.should == io	
  end

  it "should have a source attribute" do
    @instance.should respond_to(:source)
    @instance.source.should be_nil
  end

  it "should call scan when initialized with an argument" do
    lambda { @instance = AbstractScanner.new("this is a string") }.should_not raise_error
    @instance.source.string.should == "this is a string"
    io = StringIO.new("this is another string")
    lambda { @instance = AbstractScanner.new(io) }.should_not raise_error
    @instance.source.should == io
  end

  it "should increments :current_line and reset :current_char when called :scan" do
    @instance.should_receive(:read_next).once
    @instance.instance_variable_set(:@current_char,5)
    @instance.scan("b")
    @instance.current_line.should == 0
    @instance.current_char.should == -1
  end

  it "should initialize current to a Token" do
    @instance.should respond_to(:current)
    @instance.current.should be_kind_of(Token)	
  end

  it "should have a current_line attribute which is initialized at -1" do
    @instance.should respond_to(:current_line)
    @instance.current_line.should == -1
  end

  it "should have a current_char attribute which is initialized at -1" do
    @instance.should respond_to(:current_char)
    @instance.current_char.should == -1
  end

  it "should have a next method which raises a NotImplementedError" do
    lambda { @instance.next }.should raise_error(NotImplementedError)
  end
end

describe "An AbstractScanner with all its protected methods exposed should have a read_next method" do
	
  before(:each) do
    @protected_methods = AbstractScanner.protected_instance_methods(false)
    @protected_methods.each { |m| AbstractScanner.send(:public,m) }
    @instance = AbstractScanner.new
    @instance.should respond_to(:read_next)	
  end

  after(:each) do
    @protected_methods.each { |m| AbstractScanner.send(:protected,m) }
  end

  it "which reads a char from the source" do
    @instance.scan("This is a string") # scan automatically calls read_next. See the previous context.
    @instance.source.readchar.chr.should == "h"
    @instance.read_next.should == "i"
    @instance.source.readchar.chr.should == "s"
  end

  it "which handles correctly eof" do
    @instance.scan("a")
    lambda { @instance.read_next }.should_not raise_error
    @instance.source.should be_eof	
    @instance.instance_variable_get("@next_char").should be_nil
  end

  it "which store the read char into @next_char" do
    @instance.scan("ab")
    @instance.instance_variable_get("@next_char").should == "a"
    @instance.read_next
    @instance.instance_variable_get("@next_char").should == "b"
  end

  it "which reads correctly multibyte chars" do
    @instance.scan("éòù")
    @instance.read_next.should == "ò"
    @instance.read_next.should == "ù"
    @instance.read_next.should be_nil
  end

  it "which increments :current_line for every line read" do
    @instance.scan("cc\nb\ng")
    @instance.read_next.should == "c"
    @instance.current_line == 0
    @instance.read_next.should == "\n"
    @instance.current_line == 1
    @instance.read_next.should == "b"
    @instance.read_next.should == "\n"
    @instance.current_line == 2
    @instance.read_next.should == "g"
  end

  it "which increments :current_char for every char read" do
    @instance.scan("abcde")
    @instance.current_char.should == 0
		
    @instance.read_next.should == "b"
    @instance.current_char.should == 1

    @instance.read_next.should == "c"
    @instance.current_char.should == 2

    @instance.read_next.should == "d"
    @instance.current_char.should == 3

    @instance.read_next.should == "e"
    @instance.current_char.should == 4
  end

  it "which reset :current_char for every line read" do
    @instance.scan("cc\nb\ng")
    @instance.read_next.should == "c"
			
    @instance.read_next.should == "\n"
    @instance.current_char.should == -1
    @instance.current_line == 1
    @instance.read_next.should == "b"
    @instance.read_next.should == "\n"
    @instance.current_char.should == -1
    @instance.current_line == 2
    @instance.read_next.should == "g"

  end
end
