#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'

require 'lib/epub'
require 'lib/catalog'

VERSION = '0.0.1'

$root = File.expand_path(ARGV.last)

get '/' do
  @catalog = Catalog.new($root+'/')
  erb :index
end

get '/s/*' do |file|
  filename = File.expand_path(File.join(File.dirname(__FILE__), '..', 'static', file))
  # TODO: 
  case File.extname(filename)
  when '.css'
    content_type 'text/css'
  when '.js'
    content_type 'text/javascript'
  end
  send_file filename
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

get %r{/browse/(.*\.epub)/(.*)} do |file, path|
  @book = Epub.new("#{$root}/#{file}")
  @book.section(path)
end

get %r{/browse/(.*\.epub)} do |file|
  @book = Epub.new("#{$root}/#{file}")
  erb :browse
end

get '/browse/*' do |dir|
  return redirect('/') if dir == ""
  
  @back = true
  @catalog = Catalog.new("#{$root}/#{dir}")
  erb :index
end

helpers do
  def relative(uri)
    uri.sub($root+'/', '').chomp('/')
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
      $('#book').html("");
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
  <%= @book.section('Book Information') %>
</div>
