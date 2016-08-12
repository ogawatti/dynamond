module Dynamond
  class Base
    # Version 0.0.1 対応メソッド
    # * CRUD
    #  * C : create!
    #  * R : all, first, last, find, where
    #  * U : update_attribute!, update_attributes!
    #  * D : destroy
    #  * - : save!, exists?, none, new_record?, persisted?
  end

  class WattiTest < Dynamond::Base
    def initialize
      binding.pry
    end
  end
end
