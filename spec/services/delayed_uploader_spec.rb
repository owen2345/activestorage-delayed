# frozen_string_literal: true

require 'rails_helper'
include ActiveJob::TestHelper
describe ActivestorageDelayed::DelayedUploader do

  describe 'when has_one_attached' do
    let(:user) { create(:user, :with_photo_tmp) }
    let!(:delayed_upload) { user.photo_delayed_uploads.last }
    let(:inst) { described_class.new(delayed_upload) }
    let(:file_data) { JSON.parse(delayed_upload.files).first }

    describe 'when uploading defined files' do
      it 'decodes base64 encoded file into Tempfile' do
        expect(inst).to receive(:base64_to_file).with(hash_including('io')).and_call_original
        inst.call
      end

      it 'fetches the corresponding filename from the model' do
        expect(user).to receive(:ast_delayed_filename).with(:photo, anything).and_call_original
        inst.call
      end

      it 'uploads the file to the storage' do
        expect(user.photo).to receive(:attach).with(hash_including(:filename, :io, :key))
        inst.call
      end

      it 'removes the corresponding delayed_upload' do
        inst.call
        expect { delayed_upload.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'calls model#ast_delayed_on_error when failed' do
        error = 'some error'
        allow(user.photo).to receive(:attach).and_raise(error)
        expect(user).to receive(:ast_delayed_on_error).with(:photo, anything)
        inst.call
      end
    end
  end

  describe 'when has_many_attached' do
    let(:user) { perform_enqueued_jobs { create(:user, :with_certificates_tmp, qty_certs: 2) } }
    let(:delayed_upload) { user.certificates_delayed_uploads.last }
    let(:inst) { described_class.new(delayed_upload) }
    let(:file_data) { JSON.parse(delayed_upload.files).first }

    describe 'when destroying uploads' do
      it 'removes all uploads with the provided ids' do
        file_id = user.certificates.first.id
        user.update(certificates_tmp: { deleted_ids: [file_id] })
        inst.call
        expect(user.reload.certificates.find_by(id: file_id)).to be_nil
      end

      it 'removes all uploads if clean_before was defined' do
        user.update(certificates_tmp: { clean_before: true })
        inst.call
        expect(user.reload.certificates.any?).to be_falsey
      end
    end

    describe 'when uploading defined files' do
      it 'uploads the files to the storage' do
        files = 2.times.map { FixtureHelpers.as_uploadable_file('baloon.jpg') }
        user.update!(certificates_tmp: { files: files })
        expect(user.certificates).to receive(:attach).with(hash_including(:filename, :io, :key)).twice
        inst.call
      end
    end
  end
end
