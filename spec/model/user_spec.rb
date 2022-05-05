# frozen_string_literal: true

require 'rails_helper'
describe User, type: :mode do
  describe 'when validating when configured as: "required: true"' do
    it 'fails if photo_tmp and photo does not exist' do
      user = build(:user, photo_tmp: nil, photo: nil)
      expect(user.valid?).to be_falsey
    end

    it 'passes if photo_tmp exist and photo does not exist' do
      user = build(:user, :with_photo_tmp, photo: nil)
      expect(user.valid?).to be_truthy
    end

    it 'passes if photo exist and photo_tmp does not exist' do
      user = build(:user, :with_photo, photo_tmp: nil)
      expect(user.valid?).to be_truthy
    end
  end

  describe 'when uploading via background job' do
    let(:user) { create(:user, :with_photo_tmp) }

    it 'schedules a job to perform file uploading' do
      expect(ActivestorageDelayed::DelayedUploaderJob).to receive(:perform_later).with(be_a(Integer))
      user
    end

    it 'saves the provided tmp file' do
      expect(user.photo_delayed_uploads.any?).to be_truthy
    end
  end

  describe 'when uploading multiple files via background job' do
    let(:user) { create(:user, :with_certificates_tmp, qty_certs: 2) }

    it 'schedules a job to perform file uploading' do
      expect(ActivestorageDelayed::DelayedUploaderJob).to receive(:perform_later).with(be_a(Integer))
      user
    end

    it 'saves the provided tmp files' do
      last_delayed_upload = user.photo_delayed_uploads.last
      files = JSON.parse(last_delayed_upload.files)
      expect(files.count).to eq(2)
    end

    it 'saves files info of the the provided tmp files' do
      last_delayed_upload = user.photo_delayed_uploads.last
      files = JSON.parse(last_delayed_upload.files)
      expect(files.first).to match(hash_including('io', 'filename', 'content_type'))
    end

    it 'saves the provided deleted_ids to be deleted later' do
      user = create(:user, :with_certificates_tmp, qty_certs: 2)
      ids = user.photo_delayed_uploads.pluck(:id)
      user.update!(certificates_tmp: { deleted_ids: ids })
      last_delayed_upload = user.photo_delayed_uploads.last
      expect(last_delayed_upload.deleted_ids.split(',').map(&:to_i)).to eq(ids)
    end

    it 'saves the provided variant_info to be used later' do
      settings = described_class.instance_variable_get(:@ast_delayed_settings)[:photo]
      expect(settings[:variant_info]).to eq({ resize_to_fill: [200, 200] })
    end
  end
end
