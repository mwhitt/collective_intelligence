module NumPredict
  class << self
    
    def cross_validate(data, trials = 100, test = 0.05)
      error = 0.0
      trials.times do |i|
        train_set, test_set = divide_data(data, test)
        error += test_algorithm(train_set, test_set)
      end
      error / trials
    end
    
    def test_algorithm(train_set, test_set)
      error = 0.0
      test_set.each do |row|
        guess = knn_estimate(train_set, row[:input])
        error += (row[:result] - guess)**2
      end
      error / test_set.size
    end
    
    def divide_data(data, test = 0.05)
      train_set = []
      test_set = []
      data.each do |row|
        rand < test ? test_set << row : train_set << row
      end
      return train_set, test_set
    end
    
    def weighted_knn(data, vec1, k = 5)
      dlist = get_distances(data, vec1)
      avg = 0.0
      total_weight = 0.0
      
      k.times do |i|
        dist = dlist[i][0]
        idx = dlist[i][1]
        weight = gaussian(dist)
        avg += weight * data[idx][:result]
        total_weight += weight
      end
      avg / total_weight
    end
    
    def inverse_weight(dist, num = 1.0, const = 0.1)
      num / (dist + const)
    end
    
    def subtract_weight(dist, const = 1.0)
      dist > const ? 0 : const - dist
    end
    
    def gaussian(dist, sigma = 10.0)
      Math.exp(-dist**2 / (2*sigma**2))
    end
    
    def knn_estimate(data, vec1, k = 3)
      dlist = get_distances(data, vec1)
      avg = 0.0
      
      k.times do |i|
        idx = dlist[i][1]
        avg += data[idx][:result]
      end
      avg / k
    end
    
    def get_distances(data, vec1)
      distance_list = []
      data.each_index do |i|
        vec2 = data[i][:input]
        distance_list << [euclidean(vec1, vec2), i]
      end
      distance_list.sort
    end
    
    def euclidean(v1, v2)
      d = 0.0
      v1.each_index do |i|
        d += (v1[i] - v2[i])**2
      end
      Math.sqrt(d)
    end
    
    def wine_price(rating, age)
      peak_age = rating - 50
      
      price = rating / 2
      price = age > peak_age ? price * (5 - (age - peak_age)) : price * (5 * ((age + 1) / peak_age))
      
      price = 0 if price < 0
      price
    end
    
    def wine_set1
      rows = []
      300.times do |i|
        rating = rand * 50 + 50
        age = rand * 50
        
        price = wine_price(rating, age)
        
        price *= (rand * 0.4 + 0.8)
        
        rows << {:input => [rating, age], :result => price}
      end
      rows
    end
    
  end
end