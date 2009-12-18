require 'pp'

$critics={
'Lisa Rose' => {'Lady in the Water' => 2.5, 'Snakes on a Plane' => 3.5, 'Just My Luck' => 3.0, 'Superman Returns' => 3.5, 'You, Me and Dupree' => 2.5, 'The Night Listener' => 3.0}, 
'Gene Seymour' => {'Lady in the Water' => 3.0, 'Snakes on a Plane' => 3.5, 'Just My Luck' => 1.5, 'Superman Returns' => 5.0, 'The Night Listener' => 3.0, 'You, Me and Dupree' => 3.5}, 
'Michael Phillips' => {'Lady in the Water' => 2.5, 'Snakes on a Plane' => 3.0, 'Superman Returns' => 3.5, 'The Night Listener' => 4.0}, 
'Claudia Puig' => {'Snakes on a Plane' => 3.5, 'Just My Luck' => 3.0, 'The Night Listener' => 4.5, 'Superman Returns' => 4.0, 'You, Me and Dupree' => 2.5}, 
'Mick LaSalle' => {'Lady in the Water' => 3.0, 'Snakes on a Plane' => 4.0, 'Just My Luck' => 2.0, 'Superman Returns' => 3.0, 'The Night Listener' => 3.0, 'You, Me and Dupree' => 2.0}, 
'Jack Matthews' => {'Lady in the Water' => 3.0, 'Snakes on a Plane' => 4.0, 'The Night Listener' => 3.0, 'Superman Returns' => 5.0, 'You, Me and Dupree' => 3.5}, 
'Toby' => {'Snakes on a Plane' => 4.5, 'You, Me and Dupree' => 1.0, 'Superman Returns' => 4.0}
}

module Recommendations
  class << self
    
    def run
      pp get_recommendations('Toby')
    end
    
    def get_recommendations(person)
      totals = {}
      sim_sums = {}
      
      for other in $critics.keys do
        next if other == person
        sim = sim_pearson(person, other)
        next if sim <= 0 
        
        for item in $critics[other].keys do
          if !$critics[person].has_key?(item) or $critics[person][item] == 0
            totals[item] = 0 unless totals[item]
            totals[item] += $critics[other][item] * sim
            sim_sums[item] = 0 unless sim_sums[item]
            sim_sums[item] += sim
          end
        end
      end
      
      rankings = totals.inject([]) do |list, kv| 
        item = kv[0]
        total = kv[1]
        list << [total / sim_sums[item], item]
      end
      
      rankings.sort!
      rankings.reverse!
      return rankings
    end
    
    def top_matches(person, return_size = 5)
      scores = $critics.keys.inject([]){|score, other| score << [sim_pearson(person, other), other] if other != person; score}
      scores.sort!
      scores.reverse!
      return scores[0, return_size]
    end
    
    def sim_distance(person1, person2)      
      sum_of_squares = $critics[person1].inject(0) do |sum, kv|
        key = kv[0]
        value = kv[1]
        if $critics[person2].keys.include?(key)
          sum += (value - $critics[person2][key])**2
        end
        sum
      end
      
      return sum_of_squares == 0 ? 0 : 1 / (1 + sum_of_squares)
    end
    
    def sim_pearson(person1, person2)
      same_items = []
      for item in $critics[person1].keys do
        same_items << item if $critics[person2].has_key?(item)
      end
      return 0 if same_items.empty?
      
      sum1 = same_items.inject(0){|sum, item| sum += $critics[person1][item]}
      sum2 = same_items.inject(0){|sum, item| sum += $critics[person2][item]}
      
      sum1sq = same_items.inject(0){|sum, item| sum += $critics[person1][item]**2}
      sum2sq = same_items.inject(0){|sum, item| sum += $critics[person2][item]**2}
      
      p_sum = same_items.inject(0){|sum, item| sum += $critics[person1][item] * $critics[person2][item]}
      
      num = p_sum - (sum1 * sum2 / same_items.size)
      den = Math.sqrt((sum1sq - (sum1**2) / same_items.size) * (sum2sq - (sum2**2) / same_items.size))
      return 0 if den == 0
      
      return num / den
    end
    
  end
end

if __FILE__ == $0
  Recommendations.run
end