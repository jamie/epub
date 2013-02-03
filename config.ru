require 'rubygems'
require 'bundler'
Bundler.load

if File.exist?('./ENV')
  YAML.load(File.read('./ENV')).each do |k,v|
    ENV[k] = v
  end
end

require './bin/epub_catalog_db'

run Sinatra::Application
