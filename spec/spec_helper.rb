require 'bundler/setup'

require 'sqlite3'
require 'active_record'
require 'activerecord/pull/alpha/core'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.connection.create_table(:people) do |t|
  t.string :first_name
  t.string :last_name
  t.integer :age
  t.bigint :address_id
end

ActiveRecord::Base.connection.create_table(:addresses) do |t|
  t.string :street1
  t.string :street2
  t.string :city
  t.string :state
end

class Person < ActiveRecord::Base
  belongs_to :address
  accepts_nested_attributes_for :address
end

class Address < ActiveRecord::Base
  has_many :people
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
