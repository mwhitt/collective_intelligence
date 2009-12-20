require 'pp'
require 'rubygems'
require 'feedzirra'
require 'nokogiri'

module GenerateFeedVector
  class << self
    
    def run      
      apcount = {}
      word_counts = {}
      for feed_url in url_list do 
        title, wc = get_word_counts(feed_url)
        next if wc.nil?
        word_counts[title] = wc
        wc.each_pair do |word, count|
          apcount[word] = 0 unless apcount[word]
          apcount[word] += 1 if count >= 1
        end
      end
      word_list = []
      apcount.each_pair do |w, bc|
        frac = bc.to_f / url_list.size
        word_list << w if frac > 0.1 and frac < 0.5 and w.size >= 3
      end
      
      File.open(File.join(File.dirname(__FILE__), 'blogdata.txt'), 'w+') do |f|
        f.write('Blog')
        for word in word_list do
          f.write("\t#{word}")
        end
        f.write("\n")
        word_counts.each_pair do |blog, wc|
          f.write(blog)
          for word in word_list do 
            if wc[word]
              f.write("\t#{wc[word]}")
            else
              f.write("\t0")
            end
          end
          f.write("\n")
        end
      end
    end
    
    def url_list
      list = []
      File.open(File.join(File.dirname(__FILE__), 'feedlist.txt'), 'r') do |infile|
        while(line = infile.gets)
          list << line.gsub(/\s+/, '')
        end
      end
      return list
    end
    
    def get_word_counts(url)
      feed = Feedzirra::Feed.fetch_and_parse(url)
      if feed.is_a?(Fixnum) || feed.nil?
        pp url
        return nil, nil
      end
      wc = {}
      for entry in feed.entries do 
        words = get_words(entry.title.to_s + ' ' + entry.summary.to_s)
        for word in words do 
          wc[word] = 0 unless wc[word]
          wc[word] += 1
        end
      end
      return feed.title, wc
    end
    
    def get_words(html)
      words = Nokogiri::HTML.parse(html).inner_text.gsub(/[^A-Za-z]/,' ')
      words.downcase.split(/\s+/)
    end
    
  end
end

if __FILE__ == $0
  GenerateFeedVector.run
end