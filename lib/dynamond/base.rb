require 'active_support/core_ext/string/inflections'

module Dynamond
  ## Reference : http://railsdoc.com/model
  class Base
    def initialize(options={})
      initialize_attributes
      set_attributes(options)
    end

    #  [ActiveRecord]
    #    Meta.create!({ uuid: "hoge", user_id: "1" })
    #    Meta.create!([{ uuid: "hoge", user_id: "1" }, { uuid: "fuga", user_id: "2"})
    #  TODO : 複数指定
    def self.create!(options={})
      table.put_item(item: options)
      self.new(options)
    end

    # DynamoDB は Keyが二つ (Hash, Range)
    #  [ActiveRecord] rails4 以降
    #    Meta.find(1)
    #    Meta.find([1, 2, 5])
    #  [CompositePrimaryKeys]  # 複合プライマリキー対応gem
    #    Meta.find([pertition_key, sort_key])
    #    Meta.find(["hogehoge", "2"])
    #  TODO : 複数指定
    def self.find(*args)
      if args.size == 1 && args.first.instance_of?(Array)
        params = {
          key: {
            @@pertition_key => args.first.first,
            @@sort_key      => args.first.last
          }
        }
        item = table.get_item(params).item
        item ? self.new(item) : nil
      elsif args.size == 1
        ## Hash Keyを省略したものとみなす
        self.query(hash_key => args.first).first
      else
        raise ArgumentError
      end
    end

    #  [ActiveRecord] rails3 以降
    #    Meta.where(uuid: "hoge")
    #    Meta.where("uuid = '1'")
    #    Meta.where(["uuid ? and user_id ?", "hoge", "1"])
    #    Meta.where("message = ?", "fugafuga")
    #    Meta.where("message not ?", "fugafuga")
    # TODO : 複数条件, not等
    def self.where(*args)
      if args.size == 1
        conditions = args.first
      elsif args.size > 1
        conditions = args
      end

      params = {}
      case conditions
      when Hash
        # Range属性だけではkey条件指定はできない
        #  * http://blog.brains-tech.co.jp/entry/2015/09/30/222148
        # TODO : 複数指定 where(name: ['hoge', 'fuga'])
        params.merge!(conditions)
      when String
        params.merge!(generate_query_options_by_string(conditions))
      when Array
        string = conditions[1..-1].inject(conditions.first) do |string, value|
          string.sub!("?", "'#{value}'")
        end
        params.merge!(generate_query_options_by_string(string))
      else
        raise ArgumentError
      end

      query(params)
    end

    #  [ActiveRecord]
    #     Meta.first.update_attributes(message: "hogehogehoge")
    def update_attributes(options={})
      key = {
          pertition_key => self.send(pertition_key),
          sort_key =>      self.send(sort_key)
      }
      attribute_updates = options.inject({}) do |hash, (k,v)|
        hash[k] = { value: v, action: "PUT" }
        hash
      end
      table.update_item(key: key, attribute_updates: attribute_updates)

      # 更新に成功した場合にselfを更新する
      options.each do |k, v|
        method_name = k.to_s + "="
        self.send(method_name, v)
      end
      self
    end

    #  [ActiveRecord]
    #    Meta.first.destroy
    #    Meta.destroy([1, 2])
    # TODO : 引数がある場合 (モデル.destroy([引数 or 配列]))
    def destroy
      params = {
        key: {
          pertition_key => self.send(pertition_key),
          sort_key =>      self.send(sort_key)
        }
      }
      table.delete_item(params)
      self
    end

    def save!
      key = {}
      attribute_updates = {}
      instance_variables.each do |instance_variable_name|
        key_name = key_name(instance_variable_name)
        if self.primary_key.include?(key_name)
          key[key_name] = get_attribute(key_name)
        else
          attribute_updates[key_name] = { value: get_attribute(key_name), action: "PUT" }
        end
      end

      table.update_item(key: key, attribute_updates: attribute_updates)
      self
    end

    def self.first
      output = table.scan
      while output.next_page?
        output = output.next_page
      end

      item = output.items.last
      self.new(item)
    end

    def self.last
      item = table.scan(limit: 1).items.first
      self.new(item)
    end

    def self.all
      items = []
      output = table.scan(limit: 2)
      items += output.items
      while output.next_page?
        output = output.next_page
        items += output.items
      end

      items.inject([]) do |array, item|
        array << self.new(item)
        array
      end
    end

    def self.pertition_key
      initiate_key_schema unless @@pertition_key
      @@pertition_key
    end
    def self.hash_key; pertition_key; end

    def self.sort_key
      initiate_key_schema unless @@sort_key
      @@sort_key
    end
    def self.range_key; sort_key; end

    def self.key_schema
      initiate_key_schema unless @@key_schema
      @@key_schema
    end

    def self.primary_key
      initiate_key_schema if @@pertition_key.nil? || @@sort_key.nil?
      [ @@pertition_key, @@sort_key ]
    end

    def self.table_name
      self.name.underscore
    end

    def table
      self.class.table
    end

    private

    def self.client
      Dynamond.client
    end

    def self.table
      @@table ||= Aws::DynamoDB::Table.new(
        endpoint: Dynamond.endpoint,
        region:   Dynamond.region,
        name:     table_name
      )
    end

    def self.table_description
      client.describe_table(table_name: table_name).table
    end

    def initialize_attributes
      table_description.attribute_definitions.each do |definition|
        name = "@#{definition.attribute_name}".to_sym
        instance_variable_set(name, nil)
      end

      self.class.initiate_key_schema
    end

    def self.initiate_key_schema
      @@key_schema = table_description.key_schema
      table_description.key_schema.each do |schema|
        case schema.key_type
        when "HASH"  then @@pertition_key = schema.attribute_name.to_sym
        when "RANGE" then @@sort_key      = schema.attribute_name.to_sym
        end
      end
    end

    def set_attributes(options)
      options.each do |key,value|
        name = "@#{key}".to_sym
        instance_variable_set(name, value) if instance_variables.include?(name)
      end
    end

    def method_missing(key, *args)
      # インスタンスメソッドがない場合はクラスメソッドを呼び出す
      if self.class.respond_to?(key)
        args.empty? ? self.class.send(key) : self.class.send(key, args)
      elsif getter_method?(key, args)
        get_attribute(key)
      elsif setter_method?(key, args)
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
      key.to_s.include?("=") && args.size == 1
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

    def self.get_item(pertition_key, sort_key, options={})
      key = {
        @@pertition_key => pertition_key,
        @@sort_key =>      sort_key
      }.merge(options)
      item = table.get_item(key: key).item
      self.new(item)
    end

    def self.query(options={})
      unless validate_query_params(options)
        raise ArgumentError.new("Include invalid parameter. Pertition key is required.")
      end
      params = generate_query_params(options)
      items = table.query(params).items
      items.inject([]) do |array, item|
        array << self.new(item)
        array
      end
    end

    # key条件指定で有効なのは、
    #  * Hash属性のみへ条件指定
    #  * Hash属性とRange属性の両方へ条件指定
    def self.validate_query_params(params)
      keys = params.keys.map{|key| key.to_sym }
      case keys.size
      when 1 then keys.include?(hash_key)
      when 2 then keys.include?(hash_key) && keys.include?(range_key)
      else ; false
      end
    end

    def self.generate_query_params(options)
      expression_attribute_names  = {}
      expression_attribute_values = {}
      key_condition_expressions   = [] 

      options.each_with_index do |(key, value), index|
        condition_name  = "#condition_name_#{index}"
        condition_value = ":condition_value_#{index}"

        key_condition_expressions << "#{condition_name} = #{condition_value}"
        expression_attribute_names.merge!(condition_name => key.to_s)
        expression_attribute_values.merge!(condition_value => value.to_s)
      end

      { 
        expression_attribute_names:  expression_attribute_names,
        expression_attribute_values: expression_attribute_values,
        key_condition_expression: key_condition_expressions.join(" and ")
      }
    end

    def self.generate_query_options_by_string(string)
      if string.include?("and") || string.include?("AND")
        string.split(/and|AND/).inject({}) do |hash, conditional_string|
          hash.merge!(generate_query_options_by_conditional_string(conditional_string))
        end
      # TODO : elsif string.include?("or") || string.include?("OR")
      else
        generate_query_options_by_conditional_string(string)
      end
    end

    def self.generate_query_options_by_conditional_string(string)
      key   = string.split("=").first.strip
      value = string.split("=").last.strip.delete('"').delete("'")
      { key => value }
    end
  end
end
