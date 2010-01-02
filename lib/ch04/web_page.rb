require 'rubygems'
require 'active_support'
require 'mongo_mapper'
require 'stop_words'
require 'word_location'

MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database = 'search_engine'

class WebPage
  include MongoMapper::Document
  
  key :url, String
  key :links, Array, :index => true
  many :word_locations
  
  ensure_index 'word_locations.word'
  
  def before_create
    errors.add("Url has already been crawled.") if WebPage.find_by_url(self.url)
  end
  
  def separate_words(words)
    word_array = words.downcase.gsub(/[^a-z]/, ' ').split
    word_array.size.times do |i|
      word = word_array[i]
      unless StopWords.word_list.include?(word)
        self.word_locations << WordLocation.new(:word => word, :location => i)
      end
    end
  end
  
end