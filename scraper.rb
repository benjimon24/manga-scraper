require 'nokogiri'
require 'open-uri'
require 'fileutils'
require_relative 'zip'

# this is a shortcut if you have not configured OpenSSL on windows machines.
# For more information, see: https://gist.github.com/fnichol/867550
# require 'openssl'
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def request_url
  puts "Please enter the URL:"
  url = gets.chomp
  begin
    binding.pry
    $page = Nokogiri::HTML(open(url))
  rescue
    puts "URL not Found!"
    request_url
  end
end

def download_image(link)
  encoded_url = URI::encode(link.value) #this protects the scraper from invalid queries such as spaces in a url
  download = open(encoded_url)
  IO.copy_stream(download, "#{$title}/#{download.base_uri.to_s.split('/')[-1]}")
end

def create_temp_folder
  begin
    Dir.mkdir($title)
  rescue
    puts "Folder already exists!"
  end
end

#Run script
request_url
$title = $page.css('h3').text

create_temp_folder
$link = $page.css('a[title=Read]').attr('href').value + "page/"

i = 1
loop do
  begin
    current_page = $link + i.to_s

    page = Nokogiri::HTML(open(current_page))
    image_source = page.css('img').attr('src')
    puts "Downloading #{current_page}..."
    download_image(image_source)
    i += 1
  rescue
    puts "Download Complete"
    break
  end
end

#Zips files
puts "Zipping files..."
ZipFileGenerator.new($title, "#{$title}.zip").write()
puts "Zipping Complete! Cleaning up temporary files..."
FileUtils.rm_rf($title)
puts "Done!"
