#!/usr/bin/env ruby

#####################
#
# This would be so much easier if RAC supported nova host-describe
#
#####################
require_relative 'prettytable_to_array'
require 'terminal-table' #sudo gem install terminal-table

#Load Data
instances = {}
File.new('instances.csv').each do |line|
  parts = line.split(',')
  instances[parts[0]] = parts
end

volumes = {}
File.new('volumes.csv').each do |line|
  parts = line.split(',')
  volumes[parts[0]] = parts
end

host_space_instances = Hash.new(0)
#Could get this using nova hypervisor-show but we're iterating anyway.
host_space_instances_count = Hash.new(0)
host_space_volumes = Hash.new(0)
host_space_volumes_count = Hash.new(0)
overall_space_instances = 0
overall_space_instance_count = instances.length
overall_space_volumes = 0
overall_space_volume_count = volumes.length


#Load flavors
flavors = prettytable_to_array(`nova flavor-list --all`)
flavor_sizes = Hash.new(0)
flavors.each do |i|
    flavor_sizes["#{i['ID']}"] = "#{i['Disk'].to_i+i['Ephemeral'].to_i}"
end

#Load images
images = prettytable_to_array(`glance image-list --all`)
overall_space_images = 0

images.each do |i|
  if i['Size'] != ""
    overall_space_images+=i['Size'].to_i
  end
end
#Convert to GB
overall_space_images = overall_space_images / 1024 / 1024 / 1024

instances.each do |k,v|
  instance_space = flavor_sizes["#{v[2].partition(' ').last.chop[1..-1]}"].to_i
  host_space_instances["#{v[1]}"]+=instance_space.to_i
  overall_space_instances+=instance_space.to_i
  #Can't use ++ in case it doesn't exist
  host_space_instances_count["#{v[1]}"] = host_space_instances_count["#{v[1]}"] + 1
end

volumes.each do |k,v|
  host_space_volumes["#{v[1]}"]+=v[4].to_i
  overall_space_volumes+=v[4].to_i
  host_space_volumes_count["#{v[1]}"] = host_space_volumes_count["#{v[1]}"] + 1
end

rows = []
headings = ['Host', 'Instances', 'Volumes', 'Images (GB)', 'Instances Quota (GB)', 'Volumes (GB)', 'Total']

#Merge keys of host hash in case a host is only in one section and not the other.
host_space_merge = host_space_volumes.merge(host_space_instances).sort_by{ |k,v| k }

host_space_merge.each do | k,v |
  rows << [ k, host_space_instances_count["#{k}"], host_space_volumes_count["#{k}"], '0',host_space_instances["#{k}"], host_space_volumes["#{k}"], (host_space_instances["#{k}"]+host_space_volumes["#{k}"]) ]
end

rows << ['TOTAL', overall_space_instance_count, overall_space_volume_count, overall_space_images, overall_space_instances, overall_space_volumes, (overall_space_instances+overall_space_volumes+overall_space_images) ]

table = Terminal::Table.new :headings => headings, :rows => rows
puts table

