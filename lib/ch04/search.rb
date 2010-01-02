require 'web_page'
require 'pp'

module Search
  class << self
    
    def find_pages(query)
      pages = WebPage.all('word_locations.word' => {'$all' => query.split})
      scored_list(pages, query)
    end
    
    def scored_list(pages, query)
      weights = [[1.0, frequency_scores(pages, query)],
                 [1.5, location_scores(pages, query)]]
                 
      total_weights = weights.inject(Hash.new(0)) do |col, wa|
        weight = wa[0]
        scores = wa[1]
        scores.each_pair{|k,v| col[k] += weight * v}
        col
      end
      
      pages.inject([]){|col, page| col << [total_weights[page.id], page.url]}.sort.reverse.take(30)
    end
    
    def normalize_scores(scores, use_small = false)
      vsmall = 0.00001
      if use_small
        min_score = scores.values.min
        scores.inject({}) do |col, kv|
          key = kv[0]
          score = kv[1]
          col[key] = min_score / [vsmall, score].max
          col
        end
      else
        max_score = scores.values.max
        max_score = vsmall if max_score == 0
        scores.inject({}) do |col, kv|
          key = kv[0]
          score = kv[1]
          col[key] = score / max_score
          col
        end
      end
    end
    
    def location_scores(pages, query)
      terms = query.split
      locations = pages.inject({}) do |col, page|
        word_locations = page.word_locations.collect{|wl| wl if terms.include?(wl.word)}.compact
        loc = word_locations.inject(0){|sum, wl| sum += wl.location}
        col[page.id] = (loc < 1000000 ? loc : 1000000).to_f
        col
      end
      normalize_scores(locations, true)
    end
    
    def frequency_scores(pages, query)
      counts = pages.inject({}) do |col, page|
        word_array = page.word_locations.collect{|w| w.word}
        score = query.split.inject(0) do |count, word|
          count += word_array.count(word)
        end
        col[page.id] = score.to_f
        col
      end
      normalize_scores(counts)
    end
    
  end
end