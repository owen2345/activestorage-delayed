# frozen_string_literal: true

class User < ApplicationRecord
  include ActivestorageDelayed::DelayedConcern

  has_one_attached :photo do |attachable|
    attachable.variant :default, strip: true, quality: 70, resize_to_fill: [200, 200]
  end
  delayed_attach :photo, use_filename: true, required: true

  has_many_attached :certificates
  delayed_attach :certificates
end
