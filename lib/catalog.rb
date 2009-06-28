require 'digest'
require 'time'

class Catalog
  def initialize(dir='.')
    @dir = dir
  end
  
  def entries
    dirs = []
    files = []
    if File.expand_path(@dir).starts_with File.expand_path('.')
      Dir["#{@dir}*"].each do |entry|
        if File.directory?(entry)
          dir = entry#.sub(%r{^.+/},'')
          dirs << Catalog.new(dir)
        else
          files << Book.new(entry)
        end
      end
    end
    dirs + files
  end
  
  def path
    @dir + '/'
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
