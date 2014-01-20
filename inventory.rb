#!/usr/bin/env ruby
require_relative 'prettytable_to_array'
require 'rubygems'
require 'parallel'

# Get all instances
instances = prettytable_to_array(`nova list --all-tenants --fields tenant_id`)

#If instances.csv doesn't exist create it
if !File.exists?('instances.csv')
    File.write('instances.csv', '')
end

# Load the inventory
inventory = {}
File.open('instances.csv').each do |line|
  parts = line.split(',')
  inventory[parts[0]] = parts
end

# Clone the inventory so we can determine what instances no longer exist
old_inventory = inventory.clone

# Loop through the list of currently running instances.
# If the instance already exists in the inventory, flag it as still existing.
# If there's a new instance, build a record of it.
new_instances = []
Parallel.each(instances, :in_threads => 8) do |i|
  if old_inventory[i['ID']]
    old_inventory.delete(i['ID'])
  else
    instance = prettytable_to_array(`nova show #{i['ID']}`)
    puts instance
    instance_id = instance[0]['id']
    host = instance[0]['OS-EXT-SRV-ATTR:host']
    flavor = instance[0]['flavor']
    name = instance[0]['name']
    tenant_id = instance[0]['tenant_id']
    network = instance[0]['nebula network']
    ip = ''
    if instance[0].has_key?('nebula network')
      if network.split(', ').length == 2
        ip = network.split(', ')[1]
      end
    end
    new_instances << "#{instance_id},#{host},#{flavor},#{name},#{tenant_id},#{ip}"
  end
end

# Update the instances.csv file
File.open('instances.csv', 'w') do |f|
  inventory.each do |k,v|
    unless old_inventory.has_key?(k)
      f.write("#{v}\n")
    end
  end
  new_instances.each do |i|
    f.write("#{i}\n")
  end
end
