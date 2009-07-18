#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'

require 'lib/epub'
require 'lib/catalog'

VERSION = '0.0.1'

$root = File.expand_path(ARGV.last)

get '/' do
  erb :index
end

get %r{/epub/(.*)\.jpg} do |name|
  book = Epub.new("#{$root}/#{name}.epub")
  pass unless image = book.title_image
  content_type 'image/jpeg'
  image
end

get %r{/epub/(.*\.epub)} do |file|
  content_type 'application/epub+zip'
  send_file "#{$root}/#{file}"
end

get '/catalog' do
  @catalog = Catalog.new($root)
  content_type 'application/atom+xml', :charset => 'utf-8'
  erb :catalog
end

get '/catalog/*' do |dir|
  @catalog = Catalog.new("#{$root}/#{dir}")
  content_type 'application/atom+xml', :charset => 'utf-8'
  erb :catalog
end

get '/search' do
  # TODO
  # search is params[:q]
  pass
end

helpers do
  def relative(uri)
    uri.sub($root+'/', '').chomp('/')
  end
end

__END__

@@ index
<html>
  <head>
    <title>EBook Catalog</title>
  </head>
  <body>
    <h1>My Books</h1>
    <p>Load up our <a href="/catalog">catalog</a> in Stanza on your iPhone
      or iPod touch to browse and download the books.</p>
  </body>
</html>

@@ catalog
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>My Books</title>
  <updated><%= @catalog.updated %></updated>
  <author>
    <name>Anonymous</name>
    <uri>http://<%= request.env['SERVER_NAME'] %>/</uri>
    <email>anonymous@example.com</email>
  </author>
  <subtitle>epub_catalog <%= VERSION %></subtitle>
  <id><%= @catalog.identifier %></id>
  <link rel="self" type="application/atom+xml" href="http://<%= request.env['SERVER_NAME'] %>/catalog/<%= relative @catalog.path %>"/>
  <!--<link rel="search" title="Search Catalog" type="application/atom+xml" href="http://<%= request.env['SERVER_NAME'] %>/search?q={searchTerms}"/> -->
  <% @catalog.entries.each do |entry| %>
    <%= erb :_xml, :locals => {:entry => entry} %>
  <% end %>
</feed>

@@ _xml
<%= case entry
    when Epub ;    erb :_book_xml,    :locals => {:entry => entry}
    when Catalog ; erb :_catalog_xml, :locals => {:entry => entry}
    end
%>

@@ _book_xml
<entry>
  <title><%= entry.title %></title>
  <content type="xhtml">
    <div xmlns="http://www.w3.org/1999/xhtml">
      Subject: <%= entry.subject %> Language: <%= entry.language %>
    </div>
  </content>
  <id><%= entry.identifier %></id>
  <author>
    <name><%= entry.author %></name>
  </author>
  <updated><%= entry.updated %></updated>
  <link type="application/epub+zip" href="/epub/<%= relative entry.path.gsub(' ','+') %>"/>
  <% if entry.title_image %>
    <% image_uri = relative(entry.path).gsub('.epub', '.jpg') %>
    <link rel="x-stanza-cover-image" type="image/jpeg" href="<%= image_uri %>"/>
    <link rel="x-stanza-cover-image-thumbnail" type="image/jpeg" href="<%= image_uri %>"/>
  <% end %>
</entry>

@@ _catalog_xml
<entry>
  <title><%= entry.title %></title>
  <id><%= entry.identifier %></id>
  <updated><%= entry.updated %></updated>
  <link type="application/atom+xml" href="/catalog/<%= relative entry.path.gsub(' ','+') %>"/>
</entry>
