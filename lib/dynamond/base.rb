module Dynamond
  ## Reference : http://railsdoc.com/model
  class Base
    # Version 0.0.1 対応メソッド
    # * CRUD
    #  * C : create!
    #  * R : all, first, last, find, where
    #  * U : update_attribute!, update_attributes!
    #  * D : destroy
    #  * - : save!, exists?, none, new_record?, persisted?
    def initialize(args=nil)
    end

    def self.build(args=nil)
      self.new(args)
    end

    def self.create!
    end

    def self.all
    end

    def self.first
    end

    def self.last
    end

    def self.find(*args)
    end

    def self.where(args)
    end

    def self.update_attributes!
    end

    def destroy
    end

    def save!
    end

    # Hoge.exists?                 #=> テーブルに1件でもデータは存在するか確認
    # Hoge.exists?(:foo => "bar")  #=> fooがbarなデータが存在するか確認
    def exists?
    end

    def none
    end

    def new_record?
    end

    def persisted?
    end
  end
end
