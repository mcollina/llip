class NumExp

  include LLIP::Visitable
  
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def to_s
    @value.to_s
  end
end

class IdentExp
  include LLIP::Visitable
  
  attr_reader :value

  def initialize(value)
    @value = value
  end
	
  def to_s
    @value.to_s
  end
end

class AssignIdentExp
	
  include LLIP::Visitable

  attr_reader :name
  attr_reader :value

  def initialize(name,value)
    @name = name
    @value = value
  end

  def to_s
    "( #{@name} = #{@value} )"
  end

end

class OpExp

  include LLIP::Visitable

  attr_reader :op
  attr_reader :left
  attr_reader :right

  def initialize(left,right)
    @left = left
    @right = right
  end

  def to_s
    "( #{left.to_s} #{op} #{right.to_s} )"
  end

  def ==(other)
    return false if other.class != self.class

    left == other.left and right == other.right
  end
end

class PlusExp < OpExp
  def initialize(left,right)
    super
    @op = "+"
  end
end

class MinusExp < OpExp
  def initialize(left,right)
    super
    @op = "-"
  end
end

class MulExp < OpExp
  def initialize(left,right)
    super
    @op = "*"
  end
end

class DivExp < OpExp
  def initialize(left,right)
    super
    @op = "/"
  end
end




