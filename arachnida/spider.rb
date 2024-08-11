require 'optparse'

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

begin
  parser.parse!

  if ARGV.empty?
    raise OptionParser::MissingArgument, "URL"
  end

  options[:depth] = 0 unless options[:recursive]
  options[:url] = ARGV[0]

rescue OptionParser::InvalidArgument, OptionParser::MissingArgument => e
  puts "Error: #{e.message}"
  puts parser.help
  exit 1
end