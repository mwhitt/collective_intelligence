require 'pp'

class Bicluster
  attr_accessor :left, :right, :vec, :id, :distance
  
  def initialize(options)
    self.vec = options[:vec]
    self.left = options[:left]
    self.right = options[:right]
    self.distance = options[:distance] || 0.0
    self.id = options[:id]
  end
end

module Clusters
  class << self
    
    def run
      row_names, col_names, data = read_blog_data
      # print_h_cluster(h_cluster(data), row_names)
      print_k_cluster(k_cluster(data, 10), row_names)
    end
    
    def print_k_cluster(clust, labels)
      puts "------------------------------"
      puts "------------------------------"
      clust.each do |centroid|
        centroid.each do |id|
          puts labels[id]
        end
        puts "------------------------------"
        puts "------------------------------"
      end
    end
    
    def k_cluster(rows, k = 4)
      # create a list of min and max values for each point
      ranges = rows[0].size.times.inject([]) do |list, i|
        list << rows.inject([]){|col, row| col << row[i]}.minmax{|a,b| a <=> b}
      end
      # create k random points
      clusters = k.times.inject([]) do |list, j| 
        list << rows[0].size.times.inject([]) do |col, i|
           col << rand * (ranges[i][1] - ranges[i][0]) + ranges[i][0]
        end
      end
      
      last_matches = nil
      best_matches = nil
      100.times do |t|
        puts "Iteration #{t}"
        best_matches = k.times.inject([]){|a, i| a << []}
        
        rows.size.times do |j|
          row = rows[j]
          best_match = 0
          k.times do |i|
            d = pearson(clusters[i], row)
            best_match = i if d < pearson(clusters[best_match], row)
          end
          best_matches[best_match] << j
        end
        
        break if best_matches == last_matches
        last_matches = best_matches
        # move the centroids to the average of their members
        k.times do |i|
          avgs = [0.0] * rows[0].size
          if best_matches[i].size > 0
            for rowid in best_matches[i]
              rows[rowid].size.times do |m|
                avgs[m] += rows[rowid][m]
              end
            end
            avgs.size.times do |j|
              avgs[j] /= best_matches[i].size
            end
            clusters[i] = avgs
          end
        end
      end
      
      return best_matches
    end
    
    def print_h_cluster(clust, labels = nil, n = 0)
      if clust.id < 0
        puts "-"
      else
        puts labels[clust.id]
      end
      print_cluster(clust.left, labels, n + 1) if clust.left
      print_cluster(clust.right, labels, n + 1) if clust.right
    end
    
    def h_cluster(rows)
      distances = {}
      current_clust_id = -1
      
      clust = rows.size.times.inject([]){|list, c| list << Bicluster.new({:vec => rows[c], :id => c})}
      
      while clust.size > 1
        lowest_pair = [0,1]
        closest = pearson(clust[0].vec, clust[1].vec)
        
        clust.size.times do |i|
          (i + 1).upto(clust.size - 1) do |j|
            if !distances.has_key?([clust[i].id, clust[j].id])
              distances[[clust[i].id, clust[j].id]] = pearson(clust[i].vec, clust[j].vec)
            end
            d = distances[[clust[i].id, clust[j].id]]
            
            if d < closest
              closest = d
              lowest_pair = [i,j]
            end
          end
        end
        
        merg_evec = clust[0].vec.size.times.inject([]) do |vec, c| 
          vec << clust[lowest_pair[0]].vec[c] + clust[lowest_pair[1]].vec[c] / 2.0
        end
        
        new_cluster = Bicluster.new({:vec => merg_evec, 
                                     :left => clust[lowest_pair[0]], 
                                     :right => clust[lowest_pair[1]],
                                     :distance => closest, :id => current_clust_id})
        current_clust_id -= 1
        clust.slice!(lowest_pair[1])
        clust.slice!(lowest_pair[0])
        clust << new_cluster
      end
      
      return clust[0]
    end
    
    def pearson(v1, v2)
      sum1 = v1.inject(0){|sum, v| sum += v}
      sum2 = v2.inject(0){|sum, v| sum += v}
      
      sum1sq = v1.inject(0){|sum, v| sum += v**2}
      sum2sq = v2.inject(0){|sum, v| sum += v**2}
      
      p_sum = v1.size.times.inject(0){|sum, c| sum += v1[c] * v2[c]}
      
      num = p_sum - (sum1 * sum2 / v1.size)
      den = Math.sqrt((sum1sq - sum1**2 / v1.size) * (sum2sq - sum2**2 / v1.size))
      return 0 if den == 0
      
      return 1.0 - num / den
    end
    
    def read_blog_data
      lines = File.open(File.join(File.dirname(__FILE__), 'blogdata.txt'), 'r').readlines
      col_names = lines[0].strip.split("\t").drop(1)
      row_names = []
      data = [] 
      counter = 0
      for line in lines.drop(1) do 
        counter += 1

        p = line.strip.split("\t")
        row_names << p[0]
        data << p.drop(1).inject([]){|list, value| list << value.to_i}
      end
      return row_names, col_names, data
    end
    
  end
end

if __FILE__ == $0
  Clusters.run
end