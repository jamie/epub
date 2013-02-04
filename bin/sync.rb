#!/usr/bin/env ruby
require 'bundler'
Bundler.load

if File.exist?('./ENV')
  YAML.load(File.read('./ENV')).each do |k,v|
    ENV[k] = v
  end
end

require 'aws'
require 'uuid'

AWS.config(
  :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
)

s3 = AWS::S3.new

if !ENV['AWS_BUCKET']
  puts "Generating bucket, please store in AWS_BUCKET environment variable:"
  bucket = UUID.new.generate + ".com.tracefunc.epubserver"
  puts bucket
  s3.buckets.create(bucket)
  exit(0)
end
