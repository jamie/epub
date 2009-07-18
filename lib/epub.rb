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
    if node = xml(tocfile).elements["//docAuthor/text"]
      node.text
    elsif node = xml(rootfile).elements["//dc:creator[@opf:role~=aut]"] 
      node.text
    elsif node = xml(rootfile).elements["//dc:creator"] 
      node.text
    else
      'Unknown Author'
    end
  end
  
  def bad?
    begin
      @file["META-INF/container.xml"]
      tocfile
      false
    rescue TypeError, NoMethodError
      true
    end
  end
  
  def book_info_html
    html = "<table>"
    xml(rootfile).elements["//metadata"].each do |meta|
      next if meta.kind_of? REXML::Text
      attrs = meta.attributes.map{|k,v|"#{k}=#{v}"}.join(', ')
      html << "<tr><th>#{meta.name} #{attrs}</th><td>#{meta.text}</td></tr>"
    end
    html << "</table>"
    html
  end
  
  def manifest(id)
    xml(rootfile).elements.each("//manifest/item"){|item|
      return item.attributes['href'] if item.attributes['id'] == id
    }
  end
  
  def path
    @filename
  end
  
  def section(path)
    case path
    when 'Book Information'
      book_info_html
    else
      doc = REXML::Document.new(@file[path])
      content = doc.elements["/html/body/div"].to_s
      if content.empty?
        content = doc.elements["/html/body"].to_s.gsub(/<(\/?)body>/, '<\1div>')
      end
      content
    end
  end
  
  def table_of_contents
    links = []
    xml(tocfile).elements.each("//navMap/navPoint"){|nav|
      links << [
        nav.elements["navLabel/text"].text,
        absolute(nav.elements["content"].attributes["src"])
      ]
    }
    if links.empty?
      xml(rootfile).elements.each("//spine/itemref"){|item|
        links << [
          item.attributes["idref"],
          absolute(manifest(item.attributes["idref"]))
        ]
      }
    end
    links
  end
    
  def title
    xml(rootfile).elements["//dc:title"] .text
    #xml(tocfile).elements["//docTitle/text"].text
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
    xml(rootfile).elements["metadata/dc:#{name}"].text rescue ''
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
