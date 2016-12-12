require 'nokogiri'
require 'active_support/all'
require 'httparty'
require 'ruby-progressbar'
require 'pry'
require 'io/console'
require 'uri'
require 'ruby-graphviz'
require 'optparse'

require "zentool/version"
require_relative 'zentool/zendesk_article.rb'
require_relative 'zentool/graph.rb'

options = {}

OptionParser.new do |parser|
  parser.banner = "Usage: zentool [options]"

  parser.on("-h", "--help", "Show this help message") do ||
    puts parser
  end

  parser.on("-u", "--username USERNAME", "The username for the Zendesk.") do |v|
    options[:username] = v
  end

  parser.on("-p", "--password PASSWORD", "The password for the Zendesk.") do |v|
    options[:password] = v
  end

  parser.on("-l", "--link LINK", "The Zendesk URL.") do |v|
    options[:url] = v
  end
end.parse!

# Now we can use the options hash however we like.


def wrap(s, width = 20)
  s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
end

if options[:url] == NilClass
  print 'Zendesk URL: '
  options[:url] = gets.chomp
  puts
end
if options[:username] == NilClass
  print 'Zendesk username: '
  options[:username] = gets.chomp
  puts
end
if options[:password] == NilClass
  print 'Zendesk password: '
  options[:password] = STDIN.noecho(&:gets).chomp
  puts
end

puts

$zendesk_url = options[:url]
$zendesk_username = options[:username]
$zendesk_password = options[:password]

puts 'Envision Zendesk Articles'
puts '--------------------------'

zendesk = ZendeskArticle.new

puts '-> Retrieving Categories'
zendesk = ZendeskArticle.new
categories = Hash[zendesk.categories.collect { |s| [s['id'], s] }]
$categories_g = categories
puts

puts '-> Retrieving Sections'
zendesk = ZendeskArticle.new
sections = Hash[zendesk.sections.collect { |s| [s['id'], s] }]
$sections_g = sections
puts

puts '-> Retrieving Articles'
zendesk = ZendeskArticle.new
articles = zendesk.articles
$articles_g = articles
puts

puts '-> Generating article summary file: all_articles.csv'
CSV.open('all_articles.csv', 'wb') do |csv|
  csv << zendesk.export_columns
  articles.each do |hash|
    row = []
    zendesk.export_columns.each do |column|
      case column
      when 'category'
        row << categories[sections[hash['section_id']]['category_id']]['name']
      when 'section'
        row << sections[hash['section_id']]['name']
      when 'word_count'
        row << Nokogiri::HTML.parse(hash['body']).text.squish.split(' ').size
      else
        row << hash[column]
      end
    end
    csv << row
  end
end

directory = "./articles-#{DateTime.now}"

search_message = 'not yet available'
found_articles = []

puts "-> Generating individual article files in #{directory}"
Dir.mkdir(directory)
articles.each do |article|
  filename = "#{article['name']}.html".tr(' ', '-').tr('/', ':')
  filepath = "#{directory}/#{filename}"
  if article['body']
    File.open(filepath, 'w') { |f| f.write(article['body']) }
    found_articles << filename if article['body'].include? search_message
  end
end

puts "-> Generating summary of problem articles in #{directory}"
File.open('problem_articles.csv', 'w') do |file|
  file.puts 'article_filename'
  found_articles.each do |article_filename|
    file.puts(article_filename)
    puts '   - ' + article_filename
  end
end

graph = Graph.new
graph.generate
