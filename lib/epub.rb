require 'rexml/document'
require 'zippy'

class Epub
  def initialize(file)
    @filename = file
    @file = Zippy.open(file)
  end
  
  # metadata for catalog feed
  def identifier()  rootfile_meta "identifier" end
  def language()    rootfile_meta "language"   end
  def subject()     rootfile_meta "subject"    end # TODO: multiple
    
  def author
    xml(tocfile).elements["//docAuthor/text"].text
  end
  
  def bad?
    begin
      @file["META-INF/container.xml"]
      false
    rescue TypeError
      true
    end
  end
  
  def path
    @filename
  end
  
  def section(path)
    REXML::Document.new(@file[path]).elements["/html/body/div"].to_s
  end
  
  def table_of_contents
    links = []
    xml(tocfile).elements.each("navMap/navPoint"){|nav|
      links << [
        nav.elements["navLabel/text"].text,
        absolute(nav.elements["content"].attributes["src"])
      ]
    }
    links
  end
    
  def title
    xml(tocfile).elements["//docTitle/text"].text
  end
  
  def title_image
    begin
      rel_url = xml(rootfile).
        elements["//item[@media-type='image/jpeg']"].
        attributes["href"]
      url = rootfile.gsub(%r{[^/]*.opf}, rel_url)
      @file[url]
    rescue
      nil
    end
  end
  
  def updated
    t = begin
      date = meta("date[@opf:event='epub-publication']")
      Time.parse(date)
    rescue
      Time.now
    end
    t.strftime("%Y-%m-%dT%H:%M:%S+00:00")
  end

private
  def rootfile
    xml("META-INF/container.xml").
      elements["rootfiles/rootfile"].
      attributes["full-path"]
  end
  
  def rootfile_meta(name)
    xml(rootfile).elements["metadata/dc:#{name}"].text
  end

  def tocfile
    absolute xml(rootfile).elements["//item[@id='ncx']"].attributes["href"]
  end
  
  def absolute(path)
    if path[0] == "/"[0]
      path[1..-1]
    else
      [rootfile.split("/")[0...-1], path].flatten.join("/")
    end
  end
  
  def xml(path)
    REXML::Document.new(@file[path]).root
  end
end
