# frozen_string_literal: true

module ActivestorageDelayed
  class DelayedUploader
    attr_reader :delayed_upload

    def initialize(delayed_upload_id)
      @delayed_upload = delayed_upload_id if delayed_upload_id.is_a?(ActiveRecord::Base)
      @delayed_upload ||= DelayedUpload.find_by(id: delayed_upload_id)
    end

    def call
      return unless delayed_upload

      remove_files
      save_changes if upload_photos
    end

    private

    def upload_photos
      tmp_files_data.map(&method(:upload_photo)).all?
    end

    def upload_photo(file_data)
      parse_file_io(file_data) do |io|
        file_data['io'] = io
        model.send(attr_name).attach(file_data.transform_keys(&:to_sym))
        model.send("#{attr_name}_after_upload", file_data)
      end
      true
    rescue => e # rubocop:disable Style/RescueStandardError
      e.message.include?('PG::UniqueViolation:') ? raise : print_failure(e, file_data) && false
    end

    def print_failure(error, file_data = {})
      details = "#{error.message}. #{error.backtrace[0..20]}"
      key = "#{delayed_upload.id}-#{file_data['filename']}"
      Rails.logger.error("***#{self.class.name} -> Failed uploading file (#{key}): #{details}")
      model.send("#{attr_name}_error_upload", error, file_data)
    end

    def save_changes
      model.transaction do
        model.save!
        delayed_upload.destroy!
        model.send("#{attr_name}_after_upload_all")
      end
    end

    # @return [Array<Hash<io: StringIO, filename: String, content_type: String>>]
    def tmp_files_data
      @tmp_files_data ||= begin
        files = JSON.parse(delayed_upload.files || '[]')
        files.each do |file_data|
          if attr_settings[:use_filename]
            file_data['key'] = filename_for(file_data['filename'])
            file_data['filename'] = file_data['key']
          end
        end
      end
    end

    def parse_file_io(file_data, &block)
      tempfile = Tempfile.new(file_data['filename'], binmode: true)
      tempfile.write Base64.decode64(file_data['io'])
      tempfile.rewind
      transform_variation(tempfile, attr_settings[:variant_info]) do |io|
        block.call(io)
        tempfile.close
      end
    end

    # @param io [StringIO, File]
    # @param variant_info [Hash, Nil] ActiveStorage variant info. Sample: { resize_to_fit: [400, 400], convert: 'jpg' }
    def transform_variation(io, variant_info, &block)
      variant_info ? ActiveStorage::Variation.wrap(variant_info).transform(io, &block) : block.call(io)
    end

    def model
      @model ||= delayed_upload.uploadable
    end

    def filename_for(filename)
      method_name = "#{attr_name}_filename".to_sym
      model.send(method_name, filename)
    end

    def remove_files
      items = delayed_upload.uploadable.send(attr_name)
      return unless support_multiple?

      items.where(id: delayed_upload.deleted_ids.split(',')).destroy_all if delayed_upload.deleted_ids.present?
      items.destroy_all if delayed_upload.clean_before
    end

    def support_multiple?
      model.send(attr_name).class.name.include?('Many')
    end

    def attr_name
      delayed_upload.attr_name.to_sym
    end

    def attr_settings
      model.class.instance_variable_get(:@ast_delayed_settings)[attr_name]
    end
  end
end
