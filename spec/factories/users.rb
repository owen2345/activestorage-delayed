# frozen_string_literal: true

# == Schema Information
#
# Table name: photos
#
#  id            :integer          not null, primary key
#  position      :integer
#  capture_id    :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tmp_file_data :json
#
# Indexes
#
#  index_photos_on_capture_id  (capture_id)
#

require_relative '../support/fixture_helpers'
FactoryBot.define do
  factory :user do
    sequence(:name) { |i| "Sample name #{i}" }
    photo { FixtureHelpers.as_file_storage('baloon.jpg') }

    transient do
      qty_certs { 2 }
    end

    trait :with_photo do
      photo { FixtureHelpers.as_file_storage('baloon.jpg') }
    end

    trait :with_photo_tmp do
      photo { nil }
      photo_tmp { FixtureHelpers.as_uploadable_file('baloon.jpg') }
    end

    trait :with_certificates_tmp do
      certificates_tmp { qty_certs.times.map { FixtureHelpers.as_uploadable_file('baloon.jpg') } }
    end

    trait :with_certificates do
      certificates { qty_certs.times.map { FixtureHelpers.as_file_storage('baloon.jpg') } }
    end
  end
end
