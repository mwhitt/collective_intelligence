require 'web_page'
require 'pp'

module PageRank
  class << self
    
    def calculate(iterations = 20)
      iterations.times do |i|
        puts "Iteration #{i}"
        
        WebPage.all(:fields => 'id').each do |p|
          #use less memory and increase performance by fetching all data inside loop and just ids for list
          page = WebPage.find(p.id)
          pp page.url
          puts  WebPage.count('links.url' => page.url) 
          pr = 0.15
          
          #loop through all pages that link to this page to calc PR
          WebPage.all('links.url' => page.url, :fields => 'id').each do |wp|
            linker = WebPage.find(wp.id)
            pr += 0.85 * (linker.page_rank.to_f / linker.links.size.to_f)
          end

          page.update_attributes(:page_rank => pr)
        end
      end
    end
    
  end
end

if __FILE__ == $0
  PageRank.calculate
end