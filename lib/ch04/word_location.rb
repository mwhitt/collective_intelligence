require 'rubygems'
require 'active_support'
require 'mongo_mapper'

class WordLocation
  include MongoMapper::EmbeddedDocument
  
  key :word, String, :index => true
  key :location, Integer
  
end