require 'optparse'
require 'net/http'
require 'uri'
require 'fileutils'

options = {
  recursive: false,
  depth: 5,
  path: "./data"
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] URL"

  opts.on("-r", "Enable recursive download of images") do
    options[:recursive] = true
  end

  opts.on("-l N", Integer, "Max depth for recursion (requires -r)") do |level|
    options[:depth] = level
  end

  opts.on("-p PATH", "Directory path for saving downloaded files") do |path|
    options[:path] = path
  end
end

def fetch_html(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    response.body
  else
    puts("Failed to fetch the page: #{response.message} (#{response.code})")
    nil
  end
end

def extract_image_links(html)
  img_sources = []

  img_regex = /<img[^>]+src=['"]([^'"]+)['"]/i # tmp regex
  html.scan(img_regex).each do |match|
    img_sources << match[0]
  end

  img_sources.select { |src| needed_image_format?(src) }

end

def needed_image_format?(url)
  url.downcase.end_with?('.jpg', '.jpeg', '.png', '.gif', '.bmp')
end

def create_directory(directory)
  FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
end

def download_image(image_url, i1)
  # code here
end


begin
  parser.parse!

  if ARGV.empty?
    raise OptionParser::MissingArgument, "URL"
  end

  options[:depth] = 0 unless options[:recursive]
  options[:url] = ARGV[0]

  html_content = fetch_html(options[:url])
  if html_content.nil?
    raise StandardError, "Failed to fetch page content from #{url}"
  end

  image_links = extract_image_links(html_content)

  create_directory(options[:path])

  image_links.each do |image_url|
    download_image(image_url, options[:path])
  end

rescue OptionParser::InvalidArgument, OptionParser::MissingArgument, StandardError => e
  puts "Error: #{e.message}"
  puts parser.help
  exit 1
end