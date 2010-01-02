require 'web_page'
require 'pp'

module Search
  class << self
    
    def find_pages(query)
      pages = WebPage.all('word_locations.word' => {'$all' => query.split})
      scored_list(pages, query)
    end
    
    def scored_list(pages, query)
      weight = 1.0
      scores = frequency_scores(pages, query)
      pages.inject([]) do |col, page|
        col << [(weight / scores[page.id]), page.url]
      end.sort.reverse.take(30)
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