require 'rexml/document'
require 'zippy'

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
