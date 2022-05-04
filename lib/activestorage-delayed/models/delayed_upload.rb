# frozen_string_literal: true

# t.string :attr_name, null: false
# t.string :deleted_ids, default: ''
# t.boolean :clean_before, default: false
# t.text :files

module ActivestorageDelayed
  class DelayedUpload < ActiveRecord::Base
    self.table_name = 'activestorage_delayed_uploads'
    attr_accessor :tmp_files

    belongs_to :uploadable, polymorphic: true, touch: true

    before_save :parse_tmp_files
    after_create_commit do
      ActivestorageDelayed::DelayedUploaderJob.perform_later(id)
    end

    private

    def parse_tmp_files
      self.files = (tmp_files.is_a?(Array) ? tmp_files : [tmp_files]).select(&:present?).map do |file|
        {
          'io' => Base64.encode64(file.read),
          'filename' => file.try(:original_filename) || File.basename(file.path),
          'content_type' => file.try(:content_type) || Marcel::MimeType.for(file)
        }
      end.to_json
    end
  end
end
