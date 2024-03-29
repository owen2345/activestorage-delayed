# Activestorage Delayed

ActiveStorage in Rails 6 and 7 does not support to upload files in background which in most cases delays the submit process and then makes the visitor get bored or receive a timeout error.        
This is a Ruby on Rails gem to upload activestorage files in background by saving them as base64 encoded in the database (important for apps hosted in kubernetes) and be processed later.    

## Features
- Upload files in background
- Ability to add new files instead of replacing the old ones when using using `has_many_attached`
- Ability to upload files with the original filename or a custom one
- Ability to preprocess the files before uploading them (Rails 7+)     
Note: This gem assumes that the app has already configured activestorage.

## Installation
- Add this line to your application's Gemfile:
  ```ruby
    gem 'activestorage-delayed', '>= 0.1.3'
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

  has_one_attached :photo, required: true, use_filename: true, variant_info: { resize_to_fit: [400, 400], convert: 'jpg' }
  delayed_attach :photo

  has_many_attached :certificates
  delayed_attach :certificates
end

```
### `delayed_attach` accepts an optional hash with the following options:
- `required`: If set to `true`, the `photo` or the `photo_tmp` will be required before saving.
- `use_filename`: If set to `true`, the image filename will be used as the name of uploaded file instead of the hash-key used by `activestorage`
- `variant_info`: (Hash) Variant information to be performed before uploading the file.

### Examples to upload files in background 
- Upload a single file
  ```ruby
    User.create(photo_tmp: File.open('my_file.png')) # uploads the file in background
    User.create(photo: File.open('my_file.png')) # uploads the file directly
  ```
  **HTML**:
  ```haml
  f.file_field :photo_tmp
  ```

- Upload multiple files
  ```ruby
    User.create(certificates_tmp: [File.open('my_file.png'), File.open('my_file.png')])
  ```    
   **HTML**:
  ```haml
  = f.file_field :certificates_tmp, multiple: true
  ```

- Deletes first 2 certificates and uploads a new one
  ```ruby
    file_ids = User.first.certificates.limit(2).pluck(:id)
    User.first.update(certificates_tmp: { deleted_ids: file_ids, files: [File.open('my_file.png')] })
  ```
   **HTML**
  ```haml
  = file_field_tag 'user[certificates_tmp][files][]', multiple: true
  - user.certificates.each do |file|
    %li
      = image_tag(file)
      = check_box_tag 'user[certificates_tmp][deleted_ids][]', value: file.id
  ```
    
- Removes all certificates before uploading a new one
  ```ruby
    User.first.update(certificates_tmp: { clean_before: true, files: [File.open('my_file.png')] })
  ```
  
- Upload files with custom names (requires `use_filename: true`): `<attr_name>_filename`
  ```ruby
  class User < ApplicationRecord
    def photo_filename(filename)
      "#{id}-#{full_name.parameterize}#{File.extname(filename)}"
    end
  end
  ```
  When `<attr_name>_filename` is defined, then it is called to fetch the uploaded file name.    
  Note: Check [this](https://gist.github.com/owen2345/33730a452d73b6b292326bb602b0ee6b) if you want to rename an already uploaded file (remote file)

- Capture event when file upload has failed: `<attr_name>_error_upload`
  ```ruby
    class User < ApplicationRecord
      # @param error [StandardError]
      # @param file_data [Hash<'filename'>]
      def photo_error_upload(error, file_data)
        puts "Failed uploading photo #{file_data['filename']}: #{error.message}"
      end
    end
  ```

- Capture event when file has been uploaded: `<attr_name>_after_upload`
  ```ruby
    class User < ApplicationRecord
      # @param file_data [Hash<'filename'>]
      def photo_after_upload(file_data)
        puts "Photo #{file_data['filename']} has been uploaded"
      end
  
      def photo_after_upload_all
        puts "All photos have been uploaded"
      end
    end
  ```

Note:       
  `<attr_name>_delayed_uploads` is a `has_many` association that contains the list of scheduled uploads for the corresponding attribute.
  

## Contributing
Bug reports and pull requests are welcome on https://github.com/owen2345/activestorage-delayed. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.    

To ensure your contribution changes, run the tests with: `docker-compose run test`

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
