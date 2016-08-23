require 'active_support/core_ext/string/inflections'

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

    # TODO : Baseが呼ばれた時点で初期化したい
    @@key_schema = []

    def initialize(options={})
      initialize_attributes
      set_attributes(options)
    end

    def self.client
      Dynamond.client
    end

    def self.table
      @@table ||= Aws::DynamoDB::Table.new(endpoint: Dynamond.endpoint, region: Dynamond.region, name: "meta")
    end

    # TODO : ページング対応
    def self.all
      items = table.scan.items
      items.inject([]) do |instances, item|
        instances << self.new(item)
        instances
      end
    end

    # Meta.find(1, options={})
    # Meta.find([1,2,5], options={})
    # Meta.find(:first, options={})
    # Meta.find(:last, options={})
    # Meta.find(:all, options={})
    def self.find(*args)
      if args.size == 1
        case args.first
        when Integer
          # TODO
          binding.pry
        when Symbol
          # TODO
        else
          # TODO : ARの例外と合わせる
          raise ArgumentError
        end
      else
        # TODO
      end
    end

    def self.create!(item={})
      table.put_item(item: item)
      self.new(item)
    end

    def self.table_name
      self.name.underscore
    end

    def table
      self.class.table
    end

    # * create : keyにヒットするitemがなければADDされる
    # * update : keyにヒットするitemがあればPUTされる
    def save!
      key = {}
      attribute_updates = {}
      instance_variables.each do |instance_variable_name|
        key_name = key_name(instance_variable_name)
        if @@key_schema.include?(key_name)
          key[key_name] = get_attribute(key_name)
        else
          attribute_updates[key_name] = { value: get_attribute(key_name), action: "PUT" }
        end
      end

      table.update_item(key: key, attribute_updates: attribute_updates)
      self
    end

    private

    def initialize_attributes
      description = self.class.client.describe_table(table_name: self.class.table_name)

      description.table.attribute_definitions.each do |definition|
        name = "@#{definition.attribute_name}".to_sym
        instance_variable_set(name, nil)
      end

      description.table.key_schema.each do |key_schema|
        @@key_schema << key_schema.attribute_name.to_sym
      end
    end

    def set_attributes(options)
      options.each do |key,value|
        name = "@#{key}".to_sym
        instance_variable_set(name, value) if instance_variables.include?(name)
      end
    end

    def method_missing(key, *args)
      if getter_method?(key, args)
        get_attribute(key)
      elsif setter_method?(key, args) && !@@key_schema.include?(key)
        set_attribute(key, args.first)
      else
        super
      end
    end

    def getter_method?(key, args)
      instance_variables.include?(instance_variable_name(key)) && args.empty?
    end

    def get_attribute(key)
      instance_variable_get(instance_variable_name(key))
    end

    def setter_method?(key, args)
      key.to_s =~ /(.*)=\z/
      instance_variables.include?(instance_variable_name($1)) && args.size == 1
    end

    def set_attribute(key, value)
      key.to_s =~ /(.*)=\z/
      instance_variable_set(instance_variable_name($1), value)
    end

    def instance_variable_name(key)
      "@#{key}".to_sym
    end

    def key_name(instance_variable_name)
      instance_variable_name.to_s.delete("@").to_sym
    end

=begin
    def self.build(args=nil)
      self.new(args)
    end

    def self.all
    end

    def self.first
    end

    def self.last
    end

    def self.where(args)
    end

    def self.update_attributes!
    end

    def destroy
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
=end
  end
end
