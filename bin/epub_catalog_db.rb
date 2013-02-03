#!/usr/bin/env ruby
require 'bundler'
Bundler.load

require 'rubygems'
require 'sinatra'

require './lib/epub'
require './lib/catalog'

VERSION = '0.0.1'

$root = ENV['LOCAL_CATALOG_ROOT']

puts 'Loading Library'
ALL_BOOKS = Dir[File.expand_path(File.join("#{$root}", '**', '*.epub'))].map do |file|
  book = Epub.new(file)
  if book.bad?
    puts "bad epub: #{file}"
    next
  end
  uri = book.path.gsub(' ','+').sub($root, '').chomp('/')
  img_uri = uri.gsub(/.epub$/,'.jpg')
  {
    :author => book.author,
    :title => book.title,
    :id => book.identifier,
    :time => book.updated,
    :uri => uri,
    :img_uri => (img_uri if book.title_image),
    :summary => nil
  }
end.compact

BY_AUTHOR = {}
BY_TITLE  = {}
ALL_BOOKS.each do |book|
  BY_AUTHOR[book[:author]] ||= []
  BY_AUTHOR[book[:author]] << book
  
  BY_TITLE[book[:title].split(//).first.upcase] ||= []
  BY_TITLE[book[:title].split(//).first.upcase] << book  
end

get %r{^/epub/(.*)\.jpg$} do |name|
  book = Epub.new("/#{name}.epub")
  pass unless image = book.title_image
  content_type 'image/jpeg'
  image
end

get %r{^/epub/(.*\.epub)$} do |file|
  content_type 'application/epub+zip'
  send_file "#{$root}/#{file}"
end

get '/' do
  content_type 'application/atom+xml', :charset => 'utf-8'
  @catalog = [
    {:title => 'By Author', :uri => '/author'},
    {:title => 'By Title', :uri => '/title'}
  ]
  erb :catalog
end

get %r{^/(author|title)$} do |set|
  content_type 'application/atom+xml', :charset => 'utf-8'
  @catalog = Kernel.const_get("BY_#{set.upcase}").map{|title, books|
    {
      :title => title,
      :uri => "/#{set}/#{title.gsub(' ','+')}",
      :desc => "#{books.size} Books"
    }
  }.sort_by{|e|e[:title]}
  erb :catalog
end

get %r{^/(author|title)/(.*)$} do |set, key|
  content_type 'application/atom+xml', :charset => 'utf-8'
  @books = Kernel.const_get("BY_#{set.upcase}")[key]
  erb :books
end


get '/search' do
  # TODO
  # search is params[:q]
  pass
end

__END__

@@ catalog
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>My Books</title>
  <author>
    <name>Anonymous</name>
    <uri>http://<%= request.env['HTTP_HOST'] %>/</uri>
    <email>anonymous@example.com</email>
  </author>
  <subtitle>epub_catalog <%= VERSION %></subtitle>
  <link rel="self" type="application/atom+xml" href="http://<%= request.env['HTTP_HOST'] %><%= request.env['REQUEST_PATH'] %>"/>
  <link rel="search" title="Search Catalog" type="application/atom+xml" href="http://<%= request.env['HTTP_HOST'] %>/search?q={searchTerms}"/>
<% @catalog.each do |entry| %>
  <entry>
    <title><%= entry[:title] %></title>
    <link type="application/atom+xml" href="<%= entry[:uri] %>"/>
<% if entry[:desc] %>
    <content type="text"><%= entry[:desc] %></content>
<% end %>
  </entry>
<% end %>
</feed>

@@ books
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>My Books</title>
  <author>
    <name>Anonymous</name>
    <uri>http://<%= request.env['HTTP_HOST'] %>/</uri>
    <email>anonymous@example.com</email>
  </author>
  <subtitle>epub_catalog <%= VERSION %></subtitle>
  <link rel="self" type="application/atom+xml" href="http://<%= request.env['HTTP_HOST'] %><%= request.env['REQUEST_PATH'] %>"/>
  <link rel="search" title="Search Catalog" type="application/atom+xml" href="http://<%= request.env['HTTP_HOST'] %>/search?q={searchTerms}"/>
<% @books.each do |book| %>
  <entry>
    <id><%= book[:id] %></id>
    <updated><%= book[:time] %></updated>
    <title><%= book[:title] %></title>
    <author><name><%= book[:author] %></name></author>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">
        Book Summary Goes Here?
      </div>
    </content>
    <link type="application/epub+zip" href="/epub<%= book[:uri] %>"/>
<% if book[:img_uri] %>
    <link rel="x-stanza-cover-image"           type="image/jpeg" href="/epub<%= book[:img_uri] %>"/>
    <link rel="x-stanza-cover-image-thumbnail" type="image/jpeg" href="/epub<%= book[:img_uri] %>"/>
<% end %>
  </entry>
<% end %>
</feed>
