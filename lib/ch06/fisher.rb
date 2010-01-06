require 'classifier'

class Fisher < Classifier
  attr_accessor :minimums
  
  def initialize
    @minimums = Hash.new(0)
    super
  end
  
  def classify(item, default = nil)
    best = default
    max = 0.0
    categories.each do |c|    
      p = fisher_prob(item, c)
      if p > minimums[c] and p > max
        best = c
        max = p
      end
    end
    best
  end
  
  def category_prob(feature, category)
    clf = feature_prob(feature, category)
    return 0 if clf == 0
    
    freq_sum = categories.inject(0){|sum, c| sum += feature_prob(feature, c)}
    clf / freq_sum
  end
  
  def weighted_prob(feature, category, weight = 1.0, ap = 0.5)
    #use category probability instead of feature probability
    basic_prob = category_prob(feature, category)
    
    totals = categories.inject(0){|sum, c| sum += feature_count(feature, c)}
    ((weight * ap) + (totals * basic_prob)) / (weight + totals)
  end
  
  def fisher_prob(item, category)
    features = get_words(item)
    prob = features.inject(1){|p, f| p *= weighted_prob(f, category)}
        
    f_score = -2 * Math.log(prob)
        
    inv_chi2(f_score, features.size * 2)
  end
  
  # inverse chi square function
  def inv_chi2(chi, df)
    m = chi / 2.0
    sum = term = Math.exp(-m)
    (1..((df / 2).floor - 1)).each do |i|
      term *= m / i
      sum += term
    end
    [sum, 1.0].min
  end
  
end