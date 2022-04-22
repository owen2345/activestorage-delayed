# Activestorage Delayed

ActiveStorage for Rails 6 and 7 does not support to upload files in background which in most cases delays the submit process and then making the visitor get bored or receive a timeout error.
This is a Ruby on Rails gem to upload activestorage files in background by saving them as base64 encoded in the database and be processed later.

## Installation
- Add this line to your application's Gemfile:
  ```ruby
    gem 'activestorage-delayed'
  ```
- And then execute: `bundle install`
- Generate the migration: `rails g migration add_activestorage_delayed`
- Add the following content to the migration file:
    ```ruby
      create_table :activestorage_delayed_uploads do |t|
        t.references :uploadable, polymorphic: true, null: false
        t.string :attr_name, null: false
        t.string :deleted_ids, default: ''
        t.boolean :clean_before, default: false
        t.text :files
        t.timestamps
      end
    ```
- Run the migration: `rails db:migrate`


## Usage
- Include `ActivestorageDelayed::DelayedConcern`
- Add `delayed_attach` to the files you want to upload in background

```ruby
  class User < ApplicationRecord
  include ActivestorageDelayed::DelayedConcern

  has_one_attached :photo do |attachable|
    attachable.variant :default, strip: true, quality: 70, resize_to_fill: [200, 200]
  end
  delayed_attach :photo

  has_many_attached :certificates
  delayed_attach :certificates
end

```

## Contributing
Bug reports and pull requests are welcome on https://github.com/owen2345/activestorage-delayed. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.    

To ensure your contribution changes, run the tests with: `docker-compose run test`

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
