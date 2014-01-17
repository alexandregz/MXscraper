#
# Web scraper to xxxxxxx 
#
# Use JDownloader, so needs JDRemoteControl plugin active
# You need to config @dir_create_metadata (and this must exists)
#
# To use: $ ruby Scraper.rb (see & change code at bottom)
#
require 'nokogiri'
require 'fileutils'
require 'open-uri'
require 'net/http'


class Scraper
  attr_accessor :pageBooks, :books, :servers
  attr_reader :site

  def initialize
	  @site = 'http://www.xxxxxxxx.xxx/'	# important last slash

    @dir_create_metadata = '/Users/Alex/Desktop/pelis/metadata/'

    if !self.app_is_running('jDownloader')
      puts "You need to start JDownloader (also to activate JDRemoteControl and config here Port). Starting..."
      `open -a jDownloader`
      while !self.app_is_running('jDownloader')
        print "."
        sleep(1)
      end
    end

    puts ""
    puts "Site: #{@site}"
    puts "Metadata Folder: #{@dir_create_metadata}"


    # Download servers, we going to jump from one to another each download
    # I only put betters (HipFile, PutLocker, MixtureCloud, ShareBeast, sockshare)
    # To add more, just put initials. For example with http://embedupload.to/?d=abc to use PutLocker we point to http://embedupload.to/?PL=abc
    @servers = ['HP', 'PL', 'MC', 'SB', 'SH']
    #@servers = ['MC', 'SH']
    #@servers = ['MC']
    @id_server = nil     # to use servers[] 
    
    # default port to JDownloader Remote Control
    @portJDownloader = 10025
    
    @pageBooks =[] 
    @books = {}
  end
  

  def getLinkEmbeduploadAndImgDescription(page)
    doc = Nokogiri::HTML(open(page))
  
    path = page.sub(/#{@site.gsub(/\//, '\/')}/, '').chomp('/')
    @books[path] = {'url'=>nil, 'img'=>nil, 'description'=>nil, 'urlfinal'=> nil, 'server'=>nil}
  
    doc.css('a').each do |link|
      @books[path]['url'] = link.content  if link.content =~ /^http:\/\/www\.embedupload\.com\/?/
    end
  
    doc.css('img').each do |img|
      @books[path]['img'] = img['src']  if img['itemprop'] == 'image' 
    end
  
    @books[path]['description'] = doc.css('.entry-content')[0].text.gsub(/\r\n/, "\n").gsub!(/^.*\/\/\-\->/m, '') 
  end
  
  
  
  # get links to book
  def getBooksIntoPage(web)
    doc = Nokogiri::HTML(open(web))
    doc.css('a').each do |link|
      @pageBooks.push(link['href']) if link.content == 'Download'
    end
  end
  

  # last page
  def getLastPage
    doc = Nokogiri::HTML(open(@site))
  
    doc.css('a').each do |link|
      return link.text if link.text =~ /\d{2,}/ and link['href'] =~ /^#{@site.gsub(/\//, '\/')}page/
    end
  end
  

  # receive book
  def getLinkToJDownloader(book)
    puts ' getLinkToJDownloader(' +book[0]+ ')'

    firstServer = self.getServer
    server =  nil
    doc = nil

    loop do
      if server.nil?
        server = firstServer
      else
        server = self.getServer

        if server == firstServer
          puts "All servers checked for " +book[0]
          return
        end
      end


      puts 'server: '+server
      page = book[1]['url'].sub(/\?d=/, "?" + server + "=")
      puts 'page: '+page
      
      conn = open(page)
      doc = Nokogiri::HTML(open(page))
      # embedupload redirects bad petitions from some server (/?PL=xxxx, p.e.) to "generic" /?d=xxxxx, so.. it's ok
      break if page.include? conn.base_uri.request_uri()
    end
  
    #doc = Nokogiri::HTML(open(page))
  
    doc.css('a').each do |link|
       book[1]['urlfinal'] = link.text if link['target'] == '_blank'
    end
    book[1]['server'] = server 
  end
  

  def getServer
    if(@id_server)
      @id_server = @id_server+1
      @id_server = 0 if(@id_server >= @servers.length)
    end

    @id_server = 0 if @id_server.nil?

    return servers[@id_server]
  end
  



  # add book to jdownloader, using JDRemoteControl
  def addToJDownloader(book)
    begin
      uri = URI('http://localhost:' +@portJDownloader.to_s+ '/action/add/links/grabber0/start1/'+book[1]['urlfinal'])  
    rescue Exception => e
      puts YAML::dump(book[1])
      exit
    end
    
    
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri
    
      response = http.request request 
      puts 'response to add http://localhost:'+@portJDownloader.to_s+'/action/add/links/grabber0/start1/'+book[1]['urlfinal']
      puts response.body
    end
  end
  

  # create directory to download book and add description.txt and image here
  def createDescImageBook(book)
    begin
      FileUtils.mkdir_p(@dir_create_metadata+book[0])
      File.open(@dir_create_metadata+book[0]+"/description.txt", "w") {|f| f.write(book[1]['description']) }

      open(book[1]['img']) {|f|
         File.open(@dir_create_metadata+book[0]+"/img.jpg","wb") do |file|
           file.puts f.read
         end
      }
    rescue Exception => e
      puts "Exception saving metadata with " +book[0]+ ": " +e.message
    end
  end


  def app_is_running(app_name)
    `ps aux` =~ /#{app_name}/ ? true : false
  end
  
end







# lastPage = Scraper.new.getLastPage 
# #for i in lastPage.to_i-20..lastPage.to_i

# for i in 500..lastPage.to_i  
#   web = Scraper.new.site +  "/page/#{i}"


scrap = Scraper.new
web = scrap.site + "page/6/"
  puts 'Opening web '+web

  scrap.getBooksIntoPage(web)
  
  scrap.pageBooks.each do |page|
    puts 'Opening page '+page 
    scrap.getLinkEmbeduploadAndImgDescription(page)
  end
  
  scrap.books.each do |book|
    scrap.getLinkToJDownloader(book)

    puts "creating infor into filesystem about "+book[0]
    scrap.createDescImageBook(book)
    scrap.addToJDownloader(book)
  end
#end

