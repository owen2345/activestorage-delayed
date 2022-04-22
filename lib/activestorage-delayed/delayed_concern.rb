# frozen_string_literal: true

module ActivestorageDelayed
  module DelayedConcern
    extend ActiveSupport::Concern
    included do
      def self.delayed_attach(attr_name) # rubocop:disable Metrics/AbcSize
        tmp_attr_name = :"#{attr_name}_tmp"
        has_many_attr = :"#{attr_name}_delayed_uploads"
        attr_accessor tmp_attr_name
        has_many has_many_attr, as: :uploadable, dependent: :destroy, class_name: 'ActivestorageDelayed::DelayedUpload'

        # @param delayed_data [Hash<files: Array<File1, File2>, deleted_ids: Array<1, 2>, clean_before: Boolean>]
        # @param delayed_data [Array<File1, File2>]
        define_method "#{tmp_attr_name}=" do |delayed_data|
          instance_variable_set(:"@#{tmp_attr_name}", delayed_data.dup)
          delayed_data = { files: delayed_data } unless delayed_data.is_a?(Hash)
          delayed_data[:tmp_files] = delayed_data.delete(:files)
          delayed_data[:deleted_ids] = (delayed_data.delete(:deleted_ids) || []).join(',')
          delayed_data[:attr_name] = attr_name
          send(has_many_attr) << send(has_many_attr).new(delayed_data)
        end
      end
    end

    # @param _attr_name (String)
    # @param _error (Exception)
    def ast_delayed_on_error(_attr_name, _error); end

    def ast_delayed_filename(attr_name, filename)
      name = File.basename(filename, '.*').parameterize
      name = "#{SecureRandom.uuid}-#{name}" if send(attr_name).class.name.include?('Many')
      ext = File.extname(filename)
      method_name = "#{attr_name}_filename"
      respond_to?(method_name) ? send(method_name, name, ext) : "#{id}-#{name}#{ext}"
    end

    # private
    # TODO: support other services
    # def ast_rename_existent_file(attr_name)
    #   file = send(attr_name)
    #   if file.service.name == :amazon
    #     obj = file.service.send(:object_for, file.blob.key)
    #     obj.move_to(bucket: obj.bucket.name, key: ast_delayed_filename(attr_name))
    #   elsif file.service.name == :local
    #     old_path = file.service.path_for(file.blob.key)
    #     new_path = file.service.path_for(ast_delayed_filename(attr_name))
    #     FileUtils.mv(old_path, new_path)
    #   end
    # end
  end
end
