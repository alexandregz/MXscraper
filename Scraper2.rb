#
# Web scraper to xxxxxxx 
#
# You need to config @dir_create_metadata (and this must exists)
#
# To use: $ ruby script.rb (see & change code at bottom)
#
require 'nokogiri'
require 'fileutils'
require 'open-uri'
require 'net/http'
require 'uri'


class Scraper
  attr_reader :pageBooks, :books, :site

  def initialize
	  @site = 'http://www.xxxxxxxxx.xxx/'

    @dir_create_metadata = '/Users/Alex/Desktop/tmp/'

    FileUtils.mkdir_p(@dir_create_metadata) unless File.directory?(@dir_create_metadata)

    puts ""
    puts "Site: #{@site}"
    puts "Metadata Folder: #{@dir_create_metadata}"

    @pageBooks =[] 
    @books = {}
  end
  

  # open @dir_create_metadata and get all books to know how are downloaded
  def checkBooksDownloaded
    @books = Dir[@dir_create_metadata]
  end


  # get links to book
  def getBooksHome(web)
    doc = Nokogiri::HTML(open(web))

    doc.css('a[target=new]').each do |link|
      @pageBooks.push(link['href'])
    end
  end


  def getBooksIntoPage(page)
    dir = page.sub(/(.*)\/.*$/, "\\1")

    page = @site + page
    puts "Getting books from "+page
    doc = Nokogiri::HTML(open(page))

    doc.css('a').each do |link|
      if !link['href'].nil?
        downloadBook(dir+'/'+link['href']) if link['href'].match(/\.epub|\.mobi|\.pdf$/)
      end
    end
  end
  

  def downloadBook(link)
    filename = link.sub(/.*\/.*\/(.*)$/, "\\1")

    if File.exists?(@dir_create_metadata + filename)
      puts "File exists: "+filename
      return
    end

    url = URI::encode(@site + link)
    puts "Downloading "+url +"..."

    begin
      open(url) {|f|
         File.open(@dir_create_metadata + filename ,"wb") do |file|
           file.puts f.read
         end
      }
    rescue Exception => e
      puts "Exception saving book " +link+ ": " +e.message
    end
  end
  
end



scrap = Scraper.new
web = scrap.site
webHome = web +'catalogo.html'
puts 'Opening web '+webHome

scrap.getBooksHome(webHome)

scrap.pageBooks.each do |page|
  puts 'Opening page '+page
  scrap.getBooksIntoPage(page)
end

