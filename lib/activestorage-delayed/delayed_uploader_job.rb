# frozen_string_literal: true

module ActivestorageDelayed
  class DelayedUploaderJob < ActiveJob::Base # ActiveJob::Base
    queue_as :default

    # # @example DelayedJob.perform_later('PhotoUploader', :call, [1])
    # def perform(model_klass, attr_name, id)
    #   ActivestorageDelayed::DelayedUploader.new(model_klass, attr_name, id).call
    # end

    def perform(delayed_upload_id)
      ActivestorageDelayed::DelayedUploader.new(delayed_upload_id).call
    end
  end
end
