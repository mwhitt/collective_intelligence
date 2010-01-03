require 'rubygems'
require 'active_support'
require 'mongo_mapper'

class Link
  include MongoMapper::EmbeddedDocument
  
  key :url, String, :index => true
  key :words, Array, :index => true
  
end