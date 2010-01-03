require 'rubygems'
require 'anemone'
require 'web_page'
require 'uri'

module Crawler
  
  class << self
  
    def crawl
      # Anemone.crawl("http://kiwitobes.com/wiki/Categorical_list_of_programming_languages.html") do |anemone|
      Anemone.crawl("http://myfreecopyright.com") do |anemone|
        anemone.on_every_page do |page|
            puts page.url
            uri = URI.parse(page.url.to_s)
            host = "#{uri.scheme}://#{uri.host}"
            
            web_page = WebPage.new(:url => page.url.to_s)
            web_page.add_links(collect_links(page.doc, host))
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
    
    def collect_links(doc, host)
      links = doc.css('a')
      links.inject([]) do |col, link|
        unless (url = link.attribute('href').to_s).blank? || link.inner_text.blank?
          url = host + url if URI.parse(url).host.nil?
          col << [url, link.inner_text]
        end
        col
      end
    end
  
  end
  
end

if __FILE__ == $0
  Crawler.crawl
end