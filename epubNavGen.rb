#The task of this set of programs is to generate the nav documents. That being said, it should remain flexible enough that it can later be extended to also generate the content docs, if we end up going that way. Also to zipping, epubing, and validating.

require 'date'

class FormInfo
  
  def initialize(info)
    @info = info
  end
  
end

class EpubContents #an array of all the files. Is this needed for an Epub_file class that bundles the Metadata with the Epub_files? Will be needed for sorting all lthe files into the proper order. I think.
  attr_reader :oebps
  
  def initialize(oebps)
    @oebps = oebps
  end

  def get_files
    @contents = []
    Dir.chdir(@oebps)
    file_list = Dir['**/*.*']
    @number_of_files = file_list.count
    numeric_sort(file_list)
    counter = 0
    @sorted.map! do | file |
      file =~ /(.+?)\.(.+?)$/
      name = "#{$1}"
      extension = "#{$2}"
      counter += 1
      @contents.push ContentFile.new(name + "." + extension, "id", extension, extension, "Name", counter, false, false, false, false, false, false, false, false) #this is where the new info from the form needs to be fed.
    end
    refine(@contents)
    make_ncx(@contents)
    make_toc(@contents)
    make_opf(@contents)
  end

  def numeric_sort(starting)
    numbered = []
    lettered = []
    @sorted = []
    starting.each do | item |
      if item =~ /^(\d+).*?\..*?/ then
        numbered.push item
      else
        lettered.push item
      end
    end
    index = 0
    (@number_of_files - 1).times do
      numbered.each do | potential |
        potential =~ /(\d+).*?\..*?/
        if  "#{$1}".to_i <= index then
          @sorted.push potential
          numbered.delete(potential)
        end
      end
      index += 1
    end
    lettered.sort!
    lettered.each do | letter |
      @sorted.push letter
    end
  end
  
  ContentFile = Struct.new(:filename, :id, :extension, :mediatype, :toc_name, :spine_order, :nav, :scripted, :cover_img, :linear, :remote, :svg, :switch, :epub_types)
  def fileify(docs)
    docs.collect{|cell|
      ContentFile.new(cell[0], cell[1], cell[2], cell[3], cell[4], cell[5], cell[6], cell[7], cell[8], cell[9], cell[10], cell[11], cell[12])}
  end
  
  def refine(files)
    files.each do | file |
      case file.extension.downcase
      when "xhtml"
        file.mediatype = "application/xhtml+xml"
      when "ncx"
        file.mediatype = "application/x-dtbncx+xml"
      when "css"
        file.mediatype = "text/css"
      when "jpg"
        file.mediatype = "image/jpeg"
      when "jpeg"
        file.mediatype = "image/jpeg"
      when "png"
        file.mediatype = "image/png"
      when "ttf"
        file.mediatype = "application/x-font-truetype"
      when "mp4"
        file.mediatype = "video/h264"
      when "mp3"
        file.mediatype = "audio/mp3"
      when "swf"
        file.mediatype = "application/x-shockwave-flash"
      when "tif"
        file.mediatype = "image/tiff"
      when "tiff"
        file.mediatype = "image/tiff"
      when "txt"
        file.mediatype = "text/plain"
      when "gif"
        file.mediatype = "image/gif"
      when "eot"
        file.mediatype = "application/vnd.ms-fontobject"
      when "otf"
        file.mediatype = "application/octet-stream"
      when "woff"
        file.mediatype = "application/font-woff"
      when "svg"
        file.mediatype = "image/svg+xml"
      else
        file.mediatype = "unsupported"
      end
      file.nav = true if file.filename == "toc.xhtml"
      file.id = file.filename.sub(/.*?\//, "").sub(".", "_").sub(/^\d+_/, "")
      if file.extension == "xhtml" #this is where we generate the toc_name
        file.toc_name = file.filename[/(\d+_)(.*?)\.xhtml/, 2]
      end
    end
  end
  
  
  def make_ncx(files)
    ncx = File.new("toc.ncx", mode="w+:utf-8")
    ncx.puts <<_EOS_
<?xml version="1.0" encoding="UTF-8" ?>
<ncx version="2005-1" xml:lang="en" xmlns="http://www.daisy.org/z3986/2005/ncx/">

<head>
\t<meta name="dtb:uid" content="isbn"/>
\t<meta name="dtb:depth" content="1"/>
</head>

<docTitle>
\t<text></text>
</docTitle>

<navMap> <!-- form info needs to be input here -->
_EOS_
    files.each do | file |
      if file.extension == "xhtml" then
        ncx.puts <<_EOS_
\t<navPoint id="#{file.id}" playOrder="#{file.spine_order.to_s}">
\t\t<navLabel><text>#{file.toc_name}</text></navLabel>
\t\t<content src="#{file.filename}" />
\t</navPoint>
_EOS_
      else
      end
    end
    ncx.puts "</navMap>\r\n\r\n</ncx>"
  end
  
  def make_toc(files)
    toc = File.new("toc.xhtml", mode="w+:utf-8")
    toc.puts <<_EOS_
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
<title>toc.xhtml</title>
<link href="template.css" rel="stylesheet" type="text/css" />
</head>

<body>

\t<nav id="toc" epub:type="toc">
\t\t<h1 class="frontmatter">Table of Contents</h1>
\t\t<ol class="contents"> <!-- form info needs to be input here -->
_EOS_
    files.each do | file |
      if file.extension == "xhtml" then
        toc.puts "\t\t\t<li><a href=\"#{file.filename}\">#{file.toc_name}</a></li>"
      else
      end
    end
    toc.puts "\t\t</ol>\r\n\t</nav>\r\n</body>\r\n</html>"
  end
  
  def make_opf(files)
    now = DateTime.now
    opf = File.new("content.opf", mode="w+:utf-8")
    opf.puts <<_EOS_
<?xml version="1.0" encoding="UTF-8" ?>
<package xmlns="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/" unique-identifier=\"db-id\" version=\"3.0\">


<metadata>
\t<dc:title id="t1">Title</dc:title>
\t<dc:creator id="creator1">Author</dc:creator>
\t<dc:contributor id="digitalbindery">Digital Bindery</dc:contributor>
\t<meta refines="#digitalbindery" property="role" scheme="marc:relators" id="role">bkd</meta>
\t<dc:subject>Subject</dc:subject>
\t<dc:description>Description</dc:description>
\t<dc:publisher>Publisher</dc:publisher>
\t<dc:rights>Copyright</dc:rights>
\t<dc:identifier id="db-id">isbn</dc:identifier>
\t<meta property="dcterms:modified">#{now.strftime(format='%FT%TZ')}</meta>
\t<dc:language>en</dc:language>
\t<dc:date>#{now.strftime(format='%FT%TZ')}</dc:date>
</metadata>

<manifest> <!-- form info needs to be input here -->
_EOS_
    
    opf.puts "\t<item id=\"toc\" properties=\"nav\" href=\"toc.xhtml\" media-type=\"application/xhtml+xml\" />" #this can give duplicates. Better to check.
    opf.puts "\t<item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\" />"
    files.each do | file |
      opf.puts "\t<item id=\"#{file.id}\" href=\"#{file.filename}\" media-type=\"#{file.mediatype}\" />"
    end
    opf.puts "</manifest>\r\n\r\n<spine toc=\"ncx\">\r\n"
    files.each do | file |
      if file.extension == "xhtml" then
        opf.puts "\t<itemref idref=\"#{file.id}\" />"
      end
    end
    opf.puts "</spine>\r\n</package>"

  end
  
  
  
end

print "Copy and paste in the name of the OEBPS directory the content files are in: "
directory = gets.chomp

files = EpubContents.new(directory)
files.get_files