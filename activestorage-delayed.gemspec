# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/activestorage-delayed/version'

Gem::Specification.new do |spec|
  spec.name        = 'activestorage-delayed'
  spec.version     = ActivestorageDelayed::VERSION
  spec.authors     = ['Owen Peredo Diaz']
  spec.email       = ['owenperedo@gmail.com']
  spec.homepage    = 'https://github.com/owen2345/activestorage-delayed'
  spec.summary     = 'Ruby on Rails gem to upload activestorage files in background'
  spec.description = 'Ruby on Rails gem to upload activestorage files in background'

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do # rubocop:disable Style/ExpandPathArguments
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.require_paths = %w[lib]

  spec.add_dependency 'activestorage'
  spec.add_dependency 'rails'
end
