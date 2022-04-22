# frozen_string_literal: true

module ActivestorageDelayed
  class DelayedUploaderJob < ActiveJob::Base
    queue_as :default

    def perform(delayed_upload_id)
      ActivestorageDelayed::DelayedUploader.new(delayed_upload_id).call
    end
  end
end
