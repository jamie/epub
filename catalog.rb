require 'rubygems'

require 'digest'
require 'rexml/document'
require 'sinatra'
require 'time'
require 'zippy'

VERSION = '0.0.1'

ROOT = "public/epub/"

class Book
  def initialize(file)
    @filename = file
    @file = Zippy.open(file)
  end
  
  def author()      meta 'creator'    end
  def identifier()  meta 'identifier' end
  def language()    meta 'language'   end
  def subject()     meta 'subject'    end # TODO: multiple
  def title()       meta 'title'      end
  
  def path
    @filename
  end
    
  def title_image
    begin
      rel_url = xml(rootfile).
        elements["//item[@media-type='image/jpeg']"].
        attributes['href']
      url = rootfile.gsub(%r{[^/]*.opf}, rel_url)
      @file[url]
    rescue
      nil
    end
  end
  
  def updated
    t = begin
      date = meta('date[@opf:event="epub-publication"]')
      Time.parse(date)
    rescue
      Time.now
    end
    t.strftime('%Y-%m-%dT%H:%M:%S+00:00')
  end

private
  def meta(name)
    xml(rootfile).elements["metadata/dc:#{name}"].text
  end

  def rootfile
    xml('META-INF/container.xml').
      elements['rootfiles/rootfile'].
      attributes['full-path']
  end
  
  def xml(path)
    REXML::Document.new(@file[path]).root
  end
end

class Catalog
  def initialize(dir='.')
    @dir = dir
  end
  
  def entries
    if File.expand_path(@dir).starts_with File.expand_path('.')
      Dir["#{@dir}/*"].map do |entry|
        if File.directory?(entry)
          dir = entry.sub(%r{^.+/},'')
          Catalog.new(dir)
        else
          Book.new(entry)
        end
      end
    else
      []
    end
  end
  
  def path
    @dir
  end
  
  def identifier
    content = entries.map{|e|e.identifier}.join
    digest = Digest::SHA1.hexdigest(content)
    "urn:sha1:#{digest}"
  end

  def title
    @dir.sub(%r{^.+/},'')
  end
  
  def updated
    t = if entries.empty?
      Time.mktime(2009,1,1)
    else
      Time.parse entries.map{|e|e.updated}.sort.last
    end
    t.strftime('%Y-%m-%dT%H:%M:%S+00:00')
  end
end

get '/' do
  @catalog = Catalog.new(ROOT)
  erb :index
end

get '/epub/:name.jpg' do |name|
  book = Book.new("#{ROOT}/#{name}.epub")
  next unless image = book.title_image
  content_type 'image/jpeg'
  image
end

get '/catalog' do
  @catalog = Catalog.new(ROOT)
  content_type 'application/atom+xml', :charset => 'utf-8'
  erb :catalog
end

get '/catalog/:dir' do |dir|
  @catalog = Catalog.new(ROOT + dir)
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
    uri
  end
  def uri_path
    @dir.sub(%r{public/epub/*},'')
  end
  
  def uri_path
    @filename.sub(%r(public/epub/*), '/epub/').gsub('/./', '/')
  end
end

__END__

@@ index
<html>
  <head>
    <title>My Books</title>
  </head>
  <body>
    <h1>My Books</h1>
    <p>Load up our <a href="/catalog">catalog</a> in Stanza on your iPhone
      or iPod touch to browse and download the books we have on hand,
      or browse them below.</p>
    <ul>
      <% @catalog.entries.each do |entry| %>
        <li><a href="/browse/<%= entry.name %>"><%= entry.title %></a></li>
      <% end %>
    </ul>
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
  <link type="application/epub+zip" href="<%= relative entry.path %>"/>
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
