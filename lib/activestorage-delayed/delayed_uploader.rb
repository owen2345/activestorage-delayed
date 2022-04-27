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

    # TODO: check the ability to delete io with save or upload method
    # file_data['io'].close
    def upload_photos # rubocop:disable Metrics/AbcSize
      tmp_files_data.each do |file_data|
        model.send(attr_name).attach(file_data.transform_keys(&:to_sym))
      end
      true
    rescue => e # rubocop:disable Style/RescueStandardError
      Rails.logger.error("********* #{self.class.name} -> Failed uploading files: #{e.message}. #{e.backtrace[0..20]}")
      model.ast_delayed_on_error(attr_name, e)
      false
    end

    def save_changes
      model.save!
      delayed_upload.destroy!
    end

    # @return [Array<Hash<io: StringIO, filename: String, content_type: String>]
    def tmp_files_data
      @tmp_files_data ||= begin
        files = JSON.parse(delayed_upload.files || '[]')
        files.each do |file_data|
          file_data['io'] = base64_to_file(file_data)
          if attr_settings[:use_filename]
            file_data['key'] = filename_for(file_data['filename'])
            file_data['filename'] = file_data['key']
          end
        end
      end
    end

    def base64_to_file(file_data)
      tempfile = Tempfile.new(file_data['filename'])
      tempfile.binmode
      tempfile.write Base64.decode64(file_data['io'])
      tempfile.rewind
      tempfile
    end

    def model
      @model ||= delayed_upload.uploadable
    end

    def filename_for(filename)
      method_name = "#{attr_name}_filename".to_sym
      return model.send(method_name, filename) if model.respond_to?(method_name)

      name = File.basename(filename, '.*').parameterize
      name = "#{SecureRandom.uuid}-#{name}" if support_multiple?
      "#{model.id}-#{name}#{File.extname(filename)}"
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
