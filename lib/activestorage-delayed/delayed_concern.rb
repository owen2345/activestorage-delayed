# frozen_string_literal: true

module ActivestorageDelayed
  module DelayedConcern
    extend ActiveSupport::Concern
    included do
      @ast_delayed_settings = {}
      def self.delayed_attach(attr_name, required: false, use_filename: false) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @ast_delayed_settings[attr_name] = { use_filename: use_filename }
        tmp_attr_name = :"#{attr_name}_tmp"
        has_many_attr = :"#{attr_name}_delayed_uploads"
        attr_accessor tmp_attr_name

        has_many has_many_attr, as: :uploadable, dependent: :destroy, class_name: 'ActivestorageDelayed::DelayedUpload'
        if required
          validates tmp_attr_name, presence: true, unless: ->(o) { o.send(attr_name).blob }
          validates attr_name, presence: true, unless: ->(o) { o.send(tmp_attr_name) }
        end

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
  end
end