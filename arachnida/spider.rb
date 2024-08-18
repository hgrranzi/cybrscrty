require 'optparse'
require 'net/http'
require 'uri'
require 'fileutils'
require "open-uri"

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
    if level < 0
      raise OptionParser::InvalidArgument, "Depth for recursion (-l) must be a positive integer."
    end
    options[:depth] = level < 5 ? level : 5
  end

  opts.on("-p PATH", "Directory path for saving downloaded files") do |path|
    options[:path] = path
  end
end

def extract_image_links_recursively(url, depth, image_links)
  html_content = fetch_html(url)
  if html_content.nil?
    return
  end

  image_links.concat(extract_image_links(html_content, url)).uniq!
  if depth > 0
    links = extract_links(html_content, url)
    links.each do |link|
      extract_image_links_recursively(link, depth - 1, image_links)
    end
  end
end

def fetch_html(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)

  case response
  when Net::HTTPSuccess then
    return response.body
  when Net::HTTPRedirection then
    location = response['location']
    redirected_uri = URI.join(url, location)
    if redirected_uri.host == uri.host
      second_response = Net::HTTP.get_response(redirected_uri)
      return second_response.is_a?(Net::HTTPSuccess) ? second_response.body : nil
    else
      return nil
    end
  else
    puts "Warning: #{response.message} (#{response.code})"
    return nil
  end
end

def extract_links(html, base_url)
  links = []
  host = URI.parse(base_url).host

  link_regex = /<a[^>]+href=['"]([^'"]+)['"]/i # tmp regex
  html.scan(link_regex).each do |match|
    link_url = match[0]
    next if link_url.nil? || link_url.empty?
    link_url = URI.join(base_url, link_url).to_s
    begin
      if URI.parse(link_url).host == host
        links << link_url
      end
    rescue URI::InvalidURIError => e
      puts "Warning: #{e}"
    end
  end

  links.uniq
end

def extract_image_links(html, base_url)
  img_sources = []

  img_regex = /<img[^>]+src=['"]([^'"]+)['"]/i # tmp regex
  html.scan(img_regex).each do |match|
    img_url = URI.join(base_url, match[0]).to_s
    img_sources << img_url if needed_image_format?(img_url)
  end

  img_sources
end

def needed_image_format?(url)
  url.downcase.end_with?('.jpg', '.jpeg', '.png', '.gif', '.bmp')
end

def create_directory(directory)
  FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
end

def download_image(image_url, target)
  filename = File.basename(image_url)
  file_path = File.join(target, filename)

  begin
    URI.open(image_url) do |image|
      File.open(file_path, "wb") do |file|
        file.write(image.read)
      end
    end
  rescue StandardError => e
    puts "Warning: #{e.message}"
  end
end

begin
  parser.parse!

  if ARGV.empty?
    raise OptionParser::MissingArgument, "URL"
  end

  options[:depth] = 0 unless options[:recursive]
  options[:url] = ARGV[0]

  image_links = []
  extract_image_links_recursively(options[:url], options[:depth], image_links)

  create_directory(options[:path]) unless image_links.empty?

  image_links.each do |image_url|
    download_image(image_url, options[:path])
  end

rescue OptionParser::InvalidArgument, OptionParser::MissingArgument => e
  puts "Error: #{e.message}"
  puts parser.help
  exit 1
rescue StandardError => e
  puts "Error: #{e.message}"
  exit 1
end