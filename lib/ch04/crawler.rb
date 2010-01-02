require 'rubygems'
require 'anemone'
require 'web_page'

module Crawler
  
  class << self
  
    def crawl
      Anemone.crawl("http://kiwitobes.com/wiki/Categorical_list_of_programming_languages.html") do |anemone|
        anemone.on_every_page do |page|
            puts page.url
            web_page = WebPage.new(:url => page.url)
            web_page.separate_words(page.doc.at('head/title').try(:inner_text).to_s + ' ' + text_only(page.doc))
            web_page.save
        end
      end
    end
    
    def text_only(doc)
      # remove html tags
      doc.search('//script').try(:remove)
      doc.search('//style').try(:remove)
      doc.at('//head').try(:remove)
      doc.inner_text.to_s.gsub(/^\w+|\t+|\n+|\r+/,'')
    end
  
  end
  
end

if __FILE__ == $0
  Crawler.crawl
end