require 'web_page'
require 'pp'

module Search
  class << self
    
    def find_pages(query)
      pages = WebPage.all('word_locations.word' => {'$all' => query.split})
      pp scored_list(pages, query)
    end
    
    def scored_list(pages, query)
      weights = [[2.0, frequency_scores(pages, query)],
                 [1.0, location_scores(pages, query)],
                 # [1.0, link_text_scores(pages, query)],
                 # [1.0, distance_scores(pages, query)],
                 # [1.0, inbound_link_scores(pages)],
                 [1.5, page_rank_scores(pages)]]
                 
      total_weights = weights.inject(Hash.new(0)) do |col, wa|
        weight = wa[0]
        scores = wa[1]
        scores.each_pair{|k,v| col[k] += weight * v}
        col
      end
      
      pages.inject([]){|col, page| col << [total_weights[page.id], page.url]}.sort.reverse.take(30)
    end
    
    def link_text_scores(pages, query)
      terms = query.split
      link_scores = pages.inject({}){|col, page| col[page.id] = 0.0; col}
      
      pages.each do |page|
        WebPage.all('links.url' => page.url, 'links.words' => {'$in' => terms}, :fields => 'id').each do |wp|
          wp = WebPage.find(wp.id, :fields => %w(page_rank links))
          links = wp.links.find_all{|l| l.url == page.url}
          links.each do |link|
            terms.each{|term| link_scores[page.id] += wp.page_rank if link.words.include?(term)}
          end
        end
      end
      
      max_score = link_scores.values.max
      link_scores.inject({}) do |col, kv|
        key = kv[0]
        score = kv[1]
        col[key] = score.to_f / max_score
        col
      end
    end
    
    def page_rank_scores(pages)
      max_pr = pages.collect{|p| p.page_rank}.max
      pages.inject({}) do |col, page|
        col[page.id] = (page.page_rank.to_f / max_pr.to_f).to_f
        col
      end
    end
    
    def inbound_link_scores(pages)
      link_scores = pages.inject({}) do |col, page|
        col[page.id] = WebPage.count('links.url' => page.url).to_f
        col
      end
      normalize_scores(link_scores)
    end
    
    def distance_scores(pages, query)
      if query.split.size < 2
        return pages.inject({}){|col, page| col[page.id] = 1.0; col}
      end
 
      distances = pages.inject({}){|col, page| col[page.id] = 1000000.0; col}
      pages.each do |page|
        wl = word_locations(query, page)
        dist = (1..wl.size - 1).inject(0) do |sum, i|
          sum += (wl[i] - wl[i - 1]).abs
        end.to_f
        distances[page.id] = dist if dist < distances[page.id]
      end
      normalize_scores(distances, true)  
    end
    
    def location_scores(pages, query)
      locations = pages.inject({}) do |col, page|
        loc = word_locations(query, page).inject(0){|sum, wl| sum += wl}
        col[page.id] = (loc < 1000000 ? loc : 1000000).to_f
        col
      end
      normalize_scores(locations, true)
    end
    
    def frequency_scores(pages, query)
      counts = pages.inject({}) do |col, page|
        col[page.id] = word_locations(query, page).size.to_f
        col
      end
      normalize_scores(counts)
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
    
    def word_locations(query, page)
      terms = query.split
      terms.inject([]){|col, t| col << page.word_locations[t].locations}.flatten.compact.sort
    end
    
  end
end