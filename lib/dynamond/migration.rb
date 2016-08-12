require 'json'

module Dynamond
  class Migration
    # Version 0.0.1 対応メソッド
    # * DB Migrate
    #  * create database
    def initialize(options={})
      @options = symbolize_hash(options)
    end

    def create_table
      unless table = Dynamond.tables.include?(@options[:table_name])
        Dynamond.client.create_table(@options)
      end
    end

    def drop_table
      Dynamond.client.delete_table(table_name: @options[:table_name])
    end

    # TODO
    def change_table
    end

    def rename_table
    end

    def add_column
    end

    def rename_column
    end

    def change_column
    end

    def remove_column
    end

    def add_index
    end

    def remove_index
    end

    private

    def symbolize_hash(hash)
      JSON.parse(hash.to_json, symbolize_names: true)
    end
  end
end
