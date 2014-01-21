#!/usr/bin/env ruby
require_relative 'prettytable_to_array'
require 'rubygems'
require 'parallel' #gem install parallel

# Get all instances
instances = prettytable_to_array(`nova list --all-tenants --fields tenant_id`)
volumes = prettytable_to_array(`cinder list --all-tenants`)

#If instances.csv doesn't exist create it
if !File.exists?('instances.csv')
    File.write('instances.csv', '')
end
#If volumes.csv doesn't exist create it
if !File.exists?('volumes.csv')
    File.write('volumes.csv', '')
end

# Load the Instance inventory
inventory = {}
File.open('instances.csv').each do |line|
  parts = line.split(',')
  inventory[parts[0]] = parts
end

# Load the volume_inventory
volume_inventory = {}
File.open('volumes.csv').each do |line|
  parts = line.split(',')
  volume_inventory[parts[0]] = parts
end

# Clone the inventories so we can determine what instances/volumes no longer exist
old_inventory = inventory.clone
old_volume_inventory = volume_inventory.clone

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
      f.write("#{v.join(',')}")
    end
  end
  new_instances.each do |i|
    f.write("#{i}\n")
  end
end

# Loop through the list of currently created volumes.
# If the volume already exists in the volume_inventory, flag it as still existing.
# If there's a new volume, build a record of it.
new_volumes = []
Parallel.each(volumes, :in_threads => 8) do |i|
  if old_volume_inventory[i['ID']]
    old_volume_inventory.delete(i['ID'])
  else
    volume_info = prettytable_to_array(`cinder show #{i['ID']}`)
    puts volume_info
    volume_id = volume_info[0]['id']
    #attachment_id = volume_info[0]['attachments']
    display_name = volume_info[0]['display_name']
    host = volume_info[0]['os-vol-host-attr:host']
    tenant_id = volume_info[0]['os-vol-tenant-attr:tenant_id']
    size = volume_info[0]['size']
    status = volume_info[0]['status']

    new_volumes << "#{volume_id},#{host},#{display_name},#{tenant_id},#{size},#{status}"
  end
end

# Update the volumes.csv file
File.open('volumes.csv', 'w') do |f|
  volume_inventory.each do |k,v|
    unless old_volume_inventory.has_key?(k)
      f.write("#{v.join(',')}")
    end
  end
  new_volumes.each do |i|
    f.write("#{i}\n")
  end
end
