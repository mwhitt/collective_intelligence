require 'pp'

class Classifier
  attr_accessor :feature_category, :cat_count
  
  def initialize
    @feature_category = {}
    @cat_count = Hash.new(0)
  end
  
  def inc_feature_category(feature, category)
    @feature_category[feature] = Hash.new(0) unless @feature_category[feature]
    @feature_category[feature][category] += 1
  end
  
  def inc_category_count(cat)
    @cat_count[cat] += 1
  end
  
  def feature_count(feature, category)
    @feature_category[feature][category].to_f
  end
  
  def category_count(category)
    @cat_count[category].to_f
  end
  
  def total_count
    categories.inject(0){|sum, cat| sum += category_count(cat)}
  end
  
  def categories
    @cat_count.keys
  end
  
  def weighted_prob(feature, category, weight = 1.0, ap = 0.5)
    basic_prob = feature_prob(feature, category)
    
    totals = categories.inject(0){|sum, c| sum += feature_count(feature, c)}
    ((weight * ap) + (totals * basic_prob)) / (weight + totals)
  end
  
  def feature_prob(feature, category)
    return 0 if category_count(category) == 0
    
    feature_count(feature, category) / category_count(category)
  end
  
  def train(item, category)
    features = get_words(item)
    features.each{|f| inc_feature_category(f, category)}
    inc_category_count(category)
  end
  
  def get_words(text)
    text.downcase.gsub(/[^a-z]/, ' ').split.uniq.reject{|w| w.size < 2 || w.size > 20}
  end
  
  def sample_train
    train('Nobody owns the water.','good') 
    train('the quick rabbit jumps fences','good') 
    train('buy pharmaceuticals now','bad') 
    train('make quick money at the online casino','bad') 
    train('the quick brown fox jumps','good')
  end
  
end