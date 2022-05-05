# frozen_string_literal: true

require 'rails_helper'
describe ActivestorageDelayed::DelayedUploader do
  include ActiveJob::TestHelper
  before do
    mock_variation = double(transform: nil)
    allow(ActiveStorage::Variation).to receive(:wrap).and_return(mock_variation)
    allow(mock_variation).to receive(:transform) { |io, &block| block.call(io) }
  end

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

      it 'calculates filename if configured as: "use_filename: true"' do
        expect(inst).to receive(:filename_for)
        inst.call
      end

      it 'fetches the corresponding filename from the model if defined when defined: "use_filename: true"' do
        user.instance_eval do
          def photo_filename(filename)
            "custom_#{filename}"
          end
        end
        expect(user.photo).to receive(:attach).with(hash_including(filename: include('custom_')))
        inst.call
      end

      it 'uploads the file to the storage' do
        expect(user.photo).to receive(:attach).with(hash_including(:filename, :io, :key, :content_type))
        inst.call
      end

      it 'removes the corresponding delayed_upload' do
        inst.call
        expect { delayed_upload.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'calls model#<attr>_after_upload method once failed' do
        error = 'some error'
        allow(user.photo).to receive(:attach).and_raise(error)
        expect(user).to receive(:photo_error_upload).with(be_a(Exception))
        inst.call
      end

      it 'calls model#<attr>_after_upload method once uploaded' do
        expect(user).to receive(:photo_after_upload)
        inst.call
      end

      describe 'when applying variant transformations to the file to be uploaded' do
        it 'applies variant transformation if defined' do
          variant_info = { resize_to_fit: [400, 400], convert: 'jpg' }
          allow(inst).to receive(:attr_settings).and_return(variant_info: variant_info)
          expect(ActiveStorage::Variation).to receive(:wrap).with(variant_info)
          inst.call
        end

        it 'does not apply variant transformation if not defined' do
          allow(inst).to receive(:attr_settings).and_return(variant_info: nil)
          expect(ActiveStorage::Variation).not_to receive(:wrap)
          inst.call
        end
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
        expect(user.certificates).to receive(:attach).with(hash_including(:filename, :io, :content_type)).twice
        inst.call
      end
    end
  end
end
