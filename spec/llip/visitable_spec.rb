require File.dirname(__FILE__) + '/../spec_helper'
require 'visitable'

class TempClass
  include Visitable
end

describe "A class including Visitable" do
  before :each do
    @instance = TempClass.new
  end
  
  it { @instance.should respond_to(:accept) }
  
  it "should call the visitor's class method for the class" do
    visitor = mock "Visitor"
    visitor.should_receive(:visit_temp_class).and_return(:a_symbol)
    @instance.accept(visitor).should == :a_symbol
  end
end

class ChildTempClass < TempClass
end

describe "A child of a class including Visitable" do
  before :each do
    @instance = ChildTempClass.new
  end
  
  it { @instance.should respond_to(:accept) }
  
  it "should call the visitor's class method for the class" do
    visitor = mock "Visitor"
    visitor.should_receive(:visit_child_temp_class).and_return(:another_symbol)
    @instance.accept(visitor).should == :another_symbol
  end
end

