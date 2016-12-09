require "zentool/version"
require 'nokogiri'
require 'active_support/all'
require 'httparty'
require 'ruby-progressbar'
require 'pry'
require 'io/console'
require 'uri'
require 'ruby-graphviz'

require_relative 'zentool/zendesk.rb'
require_relative 'zentool/graph.rb'


def wrap(s, width = 20)
  s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
end

system 'clear'
puts 'Envision Zendesk Articles'
puts '--------------------------'

# get username and password for Zendesk
print 'Username: '
$zendesk_username = gets.chomp
print 'Password: '
$zendesk_password = STDIN.noecho(&:gets).chomp
puts
puts

zendesk = Zendesk.new

puts '-> Retrieving Categories'
zendesk = Zendesk.new
categories = Hash[zendesk.categories.collect { |s| [s['id'], s] }]
$categories_g = categories
puts

puts '-> Retrieving Sections'
zendesk = Zendesk.new
sections = Hash[zendesk.sections.collect { |s| [s['id'], s] }]
$sections_g = sections
puts

puts '-> Retrieving Articles'
zendesk = Zendesk.new
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
