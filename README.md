# Dynamond

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/dynamond`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dynamond'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dynamond

## Usage

### Setup

```
$ export DYNAMOND_ENV="development"
$ vi dynamond.yml
```

### dynamodb.yml

```dynamodb.yml
default: &default
  endpoint: 'http://localhost:9000'
  region:   'ap-northeast-1'
  tables:
    - table_name: "meta"
      attribute_definitions:
        - attribute_name: 'uuid'
          attribute_type: 'S'
        - attribute_name: 'user_id'
          attribute_type: 'S'
      key_schema:
        - attribute_name: 'uuid'
          key_type:       'HASH'
        - attribute_name: 'user_id'
          key_type:       'RANGE'
      global_secondary_indexes:
        - index_name: 'uuid'
          key_schema:
            - attribute_name: 'user_id'
              key_type:       'HASH'
            - attribute_name: 'uuid'
              key_type:       'RANGE'
          projection:
            projection_type: 'ALL'
          provisioned_throughput:
            read_capacity_units: 5
            write_capacity_units: 5
      provisioned_throughput:
        read_capacity_units: 5
        write_capacity_units: 5

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
```

### Example

```
### Configuration
require 'dynamond'

Dynamond.configuration("dynamodb.yml")
Dynamond.migrate
Dynamond.tables  #=> ["meta"]

class Meta < Dynamond::Base; end


### Create
meta = Meta.create!({ uuid: "hoge", user_id: "1" })
meta          #=> #<Meta:0x007fb3d30e1c10 @uuid="hoge", @user_id="1", @message=nil>
meta.uuid     #=> "hoge"
meta.user_id  #=> "1"
meta.message  #=> nil

meta = Meta.new({ uuid: "fuga", user_id: "1" })
meta.message = "fugafuga"
meta.save!


### Read
metas = Meta.all
Meta.find("hoge")         # Range Key省略
Meta.find(["hoge", "1"])  # Meta.find([HASH_KEY, RANGE_KEY])
Meta.all
Meta.first
Meta.last
Meta.where(uuid: "hoge")
Meta.where('uuid = "hoge"')
Meta.where("uuid = ?", "hoge")
Meta.where(uuid: "hoge", user_id: "1")
Meta.where('uuid = "fuga" AND user_id = "1"') 
Meta.where(["uuid = ? and user_id = ?", "hoge", "1"])
Meta.where(message: "fugafuga")  #=> Include invalid parameter. Pertition key is required. (ArgumentError)


### Update
meta = Meta.create!({ uuid: "piyo", user_id: "2" })
meta.message               #=> NoMethodError: undefined method `message'
meta.message = "piyopiyo"
meta.message               #=> "piyopiyo"
meta.save!
meta.update_attributes(message: "piyopiyopiyo")


### Delete
meta = Meta.find(["hoge", "1"])  #=> #<Meta:0x007fbb542a7800 @message=nil, @user_id="1", @uuid="hoge">
meta.destroy                     #=> #<Meta:0x007fbb542a7800 @message=nil, @user_id="1", @uuid="hoge">
meta = Meta.find(["hoge", "1"])  #=> nil
```
