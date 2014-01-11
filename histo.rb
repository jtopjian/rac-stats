#!/usr/bin/env ruby
require_relative 'prettytable_to_array'
require 'ascii_charts'

instances = {}
File.new('instances.csv').each do |line|
  parts = line.split(',')
  instances[parts[0]] = parts
end

# 0: instance id
# 1: host
# 2: flavor
# 3: name
# 4: tenant_id
# 5: floating ip

t_i_count = {}
instances.each do |k,v|
  if t_i_count.has_key?(v[4])
    t_i_count[v[4]] += 1
  else
    t_i_count[v[4]] = 1
  end
end

counts = []
t_i_count.values.uniq.sort.each do |v|
  counts << [v, t_i_count.values.count(v)]
end

puts AsciiCharts::Cartesian.new(counts, :bar => true, :hide_zero => true, :y_step_size => 1).draw
