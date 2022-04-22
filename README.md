# Activestorage Delayed



## Installation
- Add this line to your application's Gemfile:
```ruby
group :development do
  gem "activestorage-delayed"
end
```
- And then execute:
    ```bash
    $ bundle install
    ```
- Generate the migration:
    ```bash
    rails g migration add_activestorage_delayed
    ```
- Add the following content to the migration file:
    ```ruby
      def change
        create_table :activestorage_delayed_uploads do |t|
          t.references :uploadable, polymorphic: true, null: false
          t.string :attr_name, null: false
          t.string :deleted_ids, default: ''
          t.boolean :clean_before, default: false
          t.text :files
    
          t.timestamps
        end
      end
    ```

- Start the file watcher (Rake task)
```
bin/rails activestorage-delayed:start
```
Note: If your project is using Procfile.dev (Foreman), then you can add:
```
activestorage-delayed: bin/rails activestorage-delayed:start
```
- Start your rails application and try editing your views or stylesheets or js files to see immediate changes in your browser

## Configuration
- Make sure your Turbo settings are well configured. See https://github.com/hotwired/turbo-rails#installation (Specially #4)
- This gem by default is watching changes in: `app/assets/builds,app/views/`. This can be customized as the following: 
```
bin/rails activestorage-delayed:start app/javascripts,app/stylesheets,app/views/
```
- The hot reloader UI can be customized as the following:
```
= render '/activestorage-delayed/stream', custom_style: 'left: 20px; bottom: 20px;'
```

## Contributing
Bug reports and pull requests are welcome on https://github.com/owen2345/rails-hotreload. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.    

To ensure your contribution changes, run the tests with: `docker-compose run test`

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
