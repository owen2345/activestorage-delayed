module FixtureHelpers
  def self.as_file_storage(fixture_name)
    {
      io: File.open("/app/spec/fixtures/#{fixture_name}"),
      filename: File.basename(fixture_name)
    }
  end
  
  def self.as_uploadable_file(name)
    Rack::Test::UploadedFile.new("/app/spec/fixtures/#{name}", 'image/png')
  end
end
