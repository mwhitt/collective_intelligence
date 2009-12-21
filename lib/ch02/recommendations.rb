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
      # pp sim_distance('Lisa Rose','Gene Seymour')
      # pp sim_pearson('Lisa Rose','Gene Seymour')
      # pp top_matches('Toby')
      # pp get_recommendations('Toby')
      # pp top_matches('Superman Returns', 5, transform_prefs)
      # pp get_recommendations('Just My Luck', transform_prefs)
      # pp calculate_similar_items
      pp get_recommended_items(calculate_similar_items, 'Toby')
    end
    
    def get_recommended_items(item_match, user, data = $critics)
      user_ratings = data[user]
      scores = Hash.new(0)
      total_sim = Hash.new(0)
      
      user_ratings.each_pair do |item, rating|
        item_match[item].each do |rs|
          similarity = rs[0]
          item2 = rs[1]
          next if user_ratings.has_key?(item2)
          
          scores[item2] += similarity * rating          
          total_sim[item2] += similarity
        end
      end
      rankings = scores.inject([]) do |result, kv|
        item = kv[0]
        score = kv[1]
        result << [score / total_sim[item], item]
      end
      
      rankings.sort!
      rankings.reverse!
      return rankings
    end
    
    def calculate_similar_items(return_size = 10, data = $critics)
      result = {}
      item_prefs = transform_prefs(data)
      c = 0
      for item in item_prefs.keys do
        c += 1
        pp "#{Time.now} - count: #{c} - item size: #{item_prefs.keys.size}" if c % 100 == 0
        scores = top_matches(item, return_size, item_prefs)
        result[item] = scores
      end
      return result
    end
    
    def transform_prefs(data = $critics)
      result = {}
      for person in data.keys do 
        for item in data[person] do
          key = item[0]
          value = item[1]
          result[key] = {} unless result[key]
          result[key][person] = data[person][key]
        end
      end 
      return result
    end
    
    def get_recommendations(person, data = $critics)
      totals = Hash.new(0)
      sim_sums = Hash.new(0)
      
      for other in data.keys do
        next if other == person
        sim = sim_pearson(person, other, data)
        next if sim <= 0 
        
        for item in data[other].keys do
          if !data[person].has_key?(item) or data[person][item] == 0
            totals[item] += data[other][item] * sim
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
    
    def top_matches(person, return_size = 5, data = $critics)
      scores = data.keys.inject([]){|score, other| score << [sim_distance(person, other, data), other] if other != person; score}
      scores.sort!
      scores.reverse!
      return scores[0, return_size]
    end
    
    def sim_distance(person1, person2, data = $critics)      
      sum_of_squares = data[person1].inject(0) do |sum, kv|
        key = kv[0]
        value = kv[1]
        if data[person2].keys.include?(key)
          sum += (value - data[person2][key])**2
        end
        sum
      end
      
      return sum_of_squares == 0 ? 0 : 1 / (1 + sum_of_squares)
    end
    
    def sim_pearson(person1, person2, data = $critics)
      same_items = []
      for item in data[person1].keys do
        same_items << item if data[person2].has_key?(item)
      end
      return 0 if same_items.empty?
      
      sum1 = same_items.inject(0){|sum, item| sum += data[person1][item]}
      sum2 = same_items.inject(0){|sum, item| sum += data[person2][item]}
      
      sum1sq = same_items.inject(0){|sum, item| sum += data[person1][item]**2}
      sum2sq = same_items.inject(0){|sum, item| sum += data[person2][item]**2}
      
      p_sum = same_items.inject(0){|sum, item| sum += data[person1][item] * data[person2][item]}
      
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