# frozen_string_literal: true

class User < ApplicationRecord
  include ActivestorageDelayed::DelayedConcern

  has_one_attached :photo
  delayed_attach :photo, use_filename: true, required: true, variant_info: { resize_to_fill: [200, 200] }

  has_many_attached :certificates
  delayed_attach :certificates
end
