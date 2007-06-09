
module LLIP
  
  # It makes a class visitable like it's defined in the Visitor pattern, using the
  # double dispatch tecnique.
  #
  # It adds the accept method so for every instance of a class, ie TempClass, including it,
  # it's possible to call instance.accept(visitor) and the visitor will receive
  # a :visit_temp_class message.
  #
  # It passes this ability to its subclasses, so if the subclass is TempClassChild the visitor
  # method which will be called is :visit_temp_class_child.
  module Visitable
    def self.included(other)
      add_accept(other)
      other.extend(ClassMethods)
    end

    # It adds the accept method following the visitor pattern and the double dispatch tecnique.
    def self.add_accept(klass)
      name = klass.name.gsub(/[A-Z]+/) { |s| " " + s.downcase}.strip.gsub(" ","_")
      klass.class_eval <<-CODE
			def accept(visitor)
				visitor.visit_#{name}(self)
			end
		CODE
    end
    
    module ClassMethods
      def inherited(other)
        Visitable.add_accept(other)
        other.extend(Visitable::ClassMethods)
      end
    end
  end
end

