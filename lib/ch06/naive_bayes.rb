require 'classifier'

class NaiveBayes < Classifier
  
  def doc_prob(item, category)
    features = get_words(item)
    features.inject(1){|prob, f| prob *= weighted_prob(f, category)}
  end
  
  def prob(item, category)
    cat_prob = category_count(category) / total_count
    doc_prob = doc_prob(item, category)
    doc_prob * cat_prob
  end
  
end