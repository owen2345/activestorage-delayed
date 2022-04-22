# frozen_string_literal: true

require 'rails'
module ActivestorageDelayed
  class Railtie < ::Rails::Railtie
    railtie_name :activestorage_delayed

    config.after_initialize do |_app|
      require_relative '../../initializers/upload_default_variation'
    end
  end
end
