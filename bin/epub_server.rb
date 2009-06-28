#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'

require 'lib/book'
require 'lib/catalog'

VERSION = '0.0.1'

$root = File.expand_path(ARGV.last)

get '/' do
  @catalog = Catalog.new($root)
  erb :index
end

get '/s/*' do |file|
  filename = File.expand_path(File.join(File.dirname(__FILE__), '..', 'static', file))
  case File.extname(filename)
  when '.css'
    content_type 'text/css'
  when '.js'
    content_type 'text/javascript'
  end
  send_file filename
end

get %r{/epub/(.*)\.jpg} do |name|
  book = Book.new("#{$root}/#{name}.epub")
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

get %r{/browse/(.*\.epub)/(.*)} do |file, path|
  @book = Book.new("#{$root}/#{file}")
  @book.section(path)
end

get %r{/browse/(.*\.epub)} do |file|
  @book = Book.new("#{$root}/#{file}")
  erb :browse
end

get '/browse/*' do |dir|
  @back = true
  @catalog = Catalog.new("#{$root}/#{dir}")
  erb :index
end

get '/search' do
  # TODO
  # search is params[:q]
  pass
end

helpers do
  def relative(uri)
    uri.sub($root+'/', '')
  end
end

__END__

@@ layout
<html>
  <head>
    <title><%= [@title, "My Books"].compact.join(' - ') %></title>
    <link rel="stylesheet" href="/s/css/screen.css" type="text/css" media="screen, projection">
    <link rel="stylesheet" href="/s/css/print.css" type="text/css" media="print">
    <!--[if IE]><link rel="stylesheet" href="/s/css/ie.css" type="text/css" media="screen, projection"><![endif]-->
    <link rel="stylesheet" href="/s/css/style.css" type="text/css" media="screen, projection">
    <script src="/s/js/jquery-1.3.2.min.js" type="text/javascript"></script>
  </head>
  <body>
    <div class="container">
      <%= yield %>
    </div>
    <script type="text/javascript">
    $('#toc a').click(function() {
      $.get(this.href, function(data) {
        $('#book').html(data);
      });
      return false
    });
    </script>
  </body>
</html>

@@ index
<h1>My Books</h1>
<p>Load up our <a href="/catalog">catalog</a> in Stanza on your iPhone
  or iPod touch to browse and download the books we have on hand,
  or browse them below.</p>
<ul>
  <% if @back %>
    <li><a href="..">..</a></li>
  <% end%>
  <% @catalog.entries.each do |entry| %>
    <li>
      <a href="/browse/<%= relative entry.path %>"><%= entry.title %></a>
    </li>
  <% end %>
</ul>

@@ browse
<% @title = @book.title %>
<div id="nav" class="span-8 border">
  <div class="center">
    <h1 class="fancy"><%= @book.title %></h1>
    <h2 class="thin"> by <%= @book.author %></h2>
  </div>
  <hr>
  <ul id="toc">
  <% @book.table_of_contents.each do |label, path| %>
    <li><a href="<%= File.basename(@book.path) %>/<%= path %>"><%= label %></a></li>
  <% end %>
  </ul>
</div>
<div id="book" class="prefix-1 span-14 suffix-1 last">
  <%= @book.section(@book.table_of_contents[0][1]) %>
</div>

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
    when Book ;    erb :_book_xml,    :locals => {:entry => entry}
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
  <link type="application/epub+zip" href="/epub/<%= relative entry.path %>"/>
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
  <link type="application/atom+xml" href="/catalog/<%= relative entry.path %>"/>
</entry>
