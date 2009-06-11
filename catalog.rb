require 'rubygems'

require 'digest'
require 'rexml/document'
require 'sinatra'
require 'time'
require 'zippy'

VERSION = '0.0.1'

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
  
  def to_xml
    <<-XML
      <entry>
        <title>#{title}</title>
        <content type="xhtml">
          <div xmlns="http://www.w3.org/1999/xhtml">Subject: #{subject} Language: #{language}</div>
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
    t = begin
      date = meta('date[@opf:event="epub-publication"]')
      Time.parse(date)
    rescue
      Time.now
    end
    t.strftime('%Y-%m-%dT%H:%M:%S+00:00')
  end
  
  def uri_path
    @filename.sub(%r(public/epub/*), '/epub/')
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
      Dir["public/epub/#{@dir}/*"].map do |entry|
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
  
  def identifier
    content = entries.map{|e|e.to_xml}.join
    digest = Digest::SHA1.hexdigest(content)
    "urn:sha1:#{digest}"
  end

  def title
    @dir.sub(%r{^.+/},'')
  end
  
  def to_xml
    <<-XML
      <entry>
        <title>#{title}</title>
        <id>#{identifier}</id>
        <updated>#{updated}</updated>
        <link type="application/atom+xml" href="/catalog/#{uri_path}"/>
      </entry>
    XML
  end
  
  def updated
    t = if entries.empty?
      Time.mktime(2009,1,1)
    else
      Time.parse entries.map{|e|e.updated}.sort.last
    end
    t.strftime('%Y-%m-%dT%H:%M:%S+00:00')
  end
  
  def uri_path
    @dir.sub(%r{public/epub/*},'')
  end
end

get '/' do
  erb :index
end

get '/catalog' do
  @catalog = Catalog.new
  content_type 'application/atom+xml', :charset => 'utf-8'
  erb :catalog
end

get '/catalog/:dir' do |dir|
  @catalog = Catalog.new(dir)
  content_type 'application/atom+xml', :charset => 'utf-8'
  erb :catalog
end

get '/search' do
  # TODO
  # search is params[:q]
  pass
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
  <id><%= @catalog.identifier %></id>
  <link rel="self" type="application/atom+xml" href="http://<%= request.env['SERVER_NAME'] %>/catalog/<%= @catalog.uri_path %>"/>
  <!--<link rel="search" title="Search Catalog" type="application/atom+xml" href="http://<%= request.env['SERVER_NAME'] %>/search?q={searchTerms}"/> -->
  <% @catalog.entries.each do |entry| %>
    <%= entry.to_xml %>
  <% end %>
</feed>
