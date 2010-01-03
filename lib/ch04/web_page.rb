require 'rubygems'
require 'active_support'
require 'mongo_mapper'
require 'stop_words'
require 'word_location'
require 'link'

MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database = 'search_engine'

class WebPage
  include MongoMapper::Document
  
  key :url, String
  
  many :links
  many :word_locations do
    def [](key)
      detect { |wl| wl.word == key.to_s }
    end
  end
  
  ensure_index 'word_locations.word'
  ensure_index 'links.url'
  ensure_index 'links.words'
  
  def before_create
    errors.add("Url has already been crawled.") if WebPage.find_by_url(self.url)
  end
  
  def add_links(links_array)
    links_array.each do |link|
      url = link[0]
      word_list = link[1].downcase.gsub(/[^a-z]/, ' ').split.reject{|w| StopWords.word_list.include?(w)}
      self.links << Link.new(:url => url, :words => word_list)
    end
  end
  
  def separate_words(words)
    word_array = words.downcase.gsub(/[^a-z]/, ' ').split.reject{|w| StopWords.word_list.include?(w)}
    word_array.each_with_index do |word, i|
      if wl = self.word_locations[word]
        wl.locations << i
      else
        self.word_locations << WordLocation.new(:word => word, :locations => [i])
      end
    end
  end
  
end