require 'rubygems'
require 'sinatra'
require 'rexml/document'
require 'time'
require 'zippy'

VERSION = '0.0.1'

class Book
  def initialize(file)
    @filename = file
    @file = Zippy.open(file)
  end
  
  def author
    node(rootfile, 'metadata/dc:creator').text
  end
  
  def identifier
    node(rootfile, 'metadata/dc:identifier').text
  end
  
  def language
    node(rootfile, 'metadata/dc:language').text
  end
  
  def rootfile
    node('META-INF/container.xml', 'rootfiles/rootfile').attributes['full-path']
  end
  
  def subject
    node(rootfile, 'metadata/dc:subject').text
  end
  
  def title
    node(rootfile, 'metadata/dc:title').text
  end
  
  def to_s
    "<em>#{title}</em> by #{author}"
  end
  
  def to_xml
    <<-XML
      <entry>
        <title>#{title}</title>
        <content type="xhtml">
          <div xmlns="http://www.w3.org/1999/xhtml">Published: -500 Subject: #{subject} Language: #{language}</div>
        </content>
        <id>#{identifier}</id>
        <author>
          <name>#{author}</name>
        </author>
        <updated>#{updated}</updated>
        <link type="application/epub+zip" href="#{uri_path}"/>
        <!--
        <link rel="x-stanza-cover-image-thumbnail" type="image/png" href="http://www.billybobsbooks.com/book/artofwar.png"/>
        <link rel="x-stanza-cover-image" type="image/png" href="http://www.billybobsbooks.com/book/artofwar.png"/>
        -->
      </entry>
    XML
  end
  
  def updated
    begin
      date = node(rootfile, 'metadata/dc:date[@opf:event="epub-publication"]').text
      Time.parse(date).strftime('%Y-%m-%dT%H:%M:%S+00:00')
    rescue
      Time.now.strftime('%Y-%m-%dT%H:%M:%S+00:00')
    end
  end
  
  def uri_path
    @filename.sub(%r(public/epub/*), '/epub/')
  end

private
  def node(path, xpath)
    xml(path).elements[xpath]
  end

  def xml(path)
    REXML::Document.new(@file[path]).root
  end
end

class Catalog
  def initialize(dir)
    @dir = dir
  end
  
  def title
    @dir.sub(%r{^.+/},'')
  end
  
  def to_s
    title
  end
  
  def to_xml
    <<-XML
      <entry>
        <title>#{title}</title>
        <id>urn:uuid:1925c615-cab8-4ebb-aaaa-81da314efc61</id>
        <updated>2008-08-18T17:40:59-07:00</updated>
        <link type="application/atom+xml" href="/catalog/#{uri_path}"/>
      </entry>
    XML
  end
  
  def uri_path
    @dir.sub(%r{public/epub/*},'')
  end
end

def entries(dir="")
  full_dir = "public/epub/#{dir}"
  if File.expand_path(full_dir).starts_with File.expand_path('.')
    Dir["#{full_dir}/*"].map do |entry|
      if File.directory?(entry)
        Catalog.new(entry)
      else
        Book.new(entry)
      end
    end
  else
    []
  end
end

get '/' do
  erb :index
end

get '/catalog' do
  @catalog = Catalog.new('')
  @entries = entries
  content_type 'application/atom+xml', :charset => 'utf-8'
  erb :catalog
end

get '/catalog/:dir' do |dir|
  @catalog = Catalog.new(dir)
  @entries = entries(dir)
  content_type 'application/atom+xml', :charset => 'utf-8'
  erb :catalog
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
      or iPod touch to browse and download the books we have on hand.</p>
  </body>
</html>

@@ catalog
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>My Books</title>
  <updated>2008-08-18T17:40:58-07:00</updated>
  <author>
    <name>Anonymous</name>
    <uri>http://example.com/</uri>
    <email>anonymous@example.com</email>
  </author>
  <subtitle>epub_catalog <%= VERSION %></subtitle>
  <id>urn:uuid:60a76c80-d399-12d9-b91C-0883939e0af6</id>
  <link rel="self" type="application/atom+xml" href="http://<%= request.env['SERVER_NAME'] %>/catalog/<%= @catalog.uri_path %>"/>
  <!--<link rel="search" title="Search Catalog" type="application/atom+xml" href="http://www.billybobsbooks.com/search.php?q={searchTerms}"/> -->
  <% @entries.each do |entry| %>
    <%= entry.to_xml %>
  <% end %>
</feed>
