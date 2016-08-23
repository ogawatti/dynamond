require 'yaml'

require "dynamond/version"
require "dynamond/base"
require "dynamond/migration"

module Dynamond
  def self.configuration(filepath)
    yaml = YAML.load_file(filepath)
    options = yaml[ENV['DYNAMOND_ENV']]
    @@endpoint   = options["endpoint"]
    @@region     = options["region"]
    @@migrations = options["tables"].inject([]) do |migrations, talbe_option|
      migrations << Dynamond::Migration.new(talbe_option)
      migrations
    end

    options
  end

  def self.client
    @@client ||= Aws::DynamoDB::Client.new(endpoint: @@endpoint, region: @@region)
  end

  def self.endpoint
    @@endpoint
  end

  def self.region
    @@region
  end

  def self.migrate
    @@migrations.each do |migration|
      migration.create_table
    end
  end

  # TODO : Base Class名にした方がいいかも
  #  * ページネートされるかも...
  def self.tables
    client.list_tables.table_names
  end
end
