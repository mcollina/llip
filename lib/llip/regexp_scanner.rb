require File.dirname(__FILE__) + '/regexp_abstract_scanner'
require File.dirname(__FILE__) + '/regexp_specification'

module LLIP
  # It's a scanner for the parser RegexpParser. It has two kind of token: :char and :symbol.
  # * char: every character.
  # * symbol: . * + ( ) \ |
  class RegexpScanner < RegexpAbstractScanner
    
    # It represents the regular expression '.'
    CHAR = LLIP::RegexpSpecification.new(:char)
    
    CHAR.add_state
    CHAR.init.error = CHAR.add_state(:final => true)
    
    add_regexp(CHAR)
    
    # It represents the regular expression '(.|*|+|\(|\)|\\|\|)' so it matches the chars: . * + ( ) \ |
    SYMBOL = LLIP::RegexpSpecification.new(:symbol)
    
    SYMBOL.add_state
    final = SYMBOL.add_state(:final => true)
    SYMBOL.init['.'] = final
    SYMBOL.init['*'] = final
    SYMBOL.init['+'] = final
    SYMBOL.init['('] = final
    SYMBOL.init[')'] = final
    SYMBOL.init['\\'] = final
    SYMBOL.init['|'] = final
    
    add_regexp(SYMBOL)
  end
end
