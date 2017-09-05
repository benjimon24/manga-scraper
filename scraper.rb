require 'nokogiri'
require 'open-uri'
require 'zip'
require 'fileutils'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class ZipFileGenerator
  # This is a simple example which uses rubyzip to
  # recursively generate a zip file from the contents of
  # a specified directory. The directory itself is not
  # included in the archive, rather just its contents.
  #
  # Usage:
  #   directoryToZip = "/tmp/input"
  #   outputFile = "/tmp/out.zip"
  #   zf = ZipFileGenerator.new(directoryToZip, outputFile)
  #   zf.write()

  # Initialize with the directory to zip and the location of the output archive.
  def initialize(inputDir, outputFile)
    @inputDir = inputDir
    @outputFile = outputFile
  end

  # Zip the input directory.
  def write()
    entries = Dir.entries(@inputDir); entries.delete("."); entries.delete("..")
    io = Zip::File.open(@outputFile, Zip::File::CREATE);

    writeEntries(entries, "", io)
    io.close();
  end

  # A helper method to make the recursion work.
  private
  def writeEntries(entries, path, io)

    entries.each { |e|
      zipFilePath = path == "" ? e : File.join(path, e)
      diskFilePath = File.join(@inputDir, zipFilePath)
      puts "Deflating " + diskFilePath
      if  File.directory?(diskFilePath)
        io.mkdir(zipFilePath)
        subdir =Dir.entries(diskFilePath); subdir.delete("."); subdir.delete("..")
        writeEntries(subdir, zipFilePath, io)
      else
        io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read())}
      end
    }
  end

end

def request_url
  puts "Please enter the URL:"
  url = gets.chomp
  begin
    $page = Nokogiri::HTML(open(url))
  rescue
    puts "URL not Found!"
    request_url
  end
end

def download_image(link)
  download = open(link)
  IO.copy_stream(download, "#{$title}/#{download.base_uri.to_s.split('/')[-1]}")
end

request_url
$title = $page.css('h3').text

begin
  Dir.mkdir($title)
rescue
  puts "Folder already exists!"
end

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

puts "Zipping files..."
ZipFileGenerator.new($title, "#{$title}.zip").write()
puts "Zipping Complete! Cleaning up temporary files..."
FileUtils.rm_rf($title)
puts "Done!"
