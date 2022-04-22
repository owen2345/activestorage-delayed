# frozen_string_literal: true

# Ability to auto apply :default variant before uploading original image
module ActivetoragePreprocessDefaultVariation
  def self.prepended(base)
    base.extend(ClassMethods)
  end

  def upload_without_unfurling(io)
    variant = attachments.first.try(:variants)
    default_variant = variant ? variant[:default] : nil
    if default_variant && self.class.enabled_default_variant?
      ActiveStorage::Variation.wrap(default_variant).transform(io) do |output|
        unfurl output, identify: identify
        super(output)
      end
    else
      super(io)
    end
  end

  module ClassMethods
    # To improve testing performance, we don't want to preprocess images in test environment
    def enabled_default_variant?
      !Rails.env.test?
    end
  end
end

ActiveStorage::Blob.prepend ActivetoragePreprocessDefaultVariation
