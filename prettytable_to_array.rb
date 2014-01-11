# https://raw.github.com/stackforge/cookbook-openstack-common/master/libraries/parse.rb
def prettytable_to_array table
  ret = []
  return ret if table == nil
  indicies = []
  (table.split(/$/).collect{|x| x.strip}).each { |line|
    unless line.start_with?('+--') or line.empty?
      cols = line.split('|').collect{|x| x.strip}
      cols.shift
      if indicies == []
        indicies = cols
        next
      end
      newobj = {}
      cols.each { |val|
        newobj[indicies[newobj.length]] = val
      }
      ret.push(newobj)
    end
  }
  # this kinda sucks, but some prettytable data comes
  # as Property Value pairs. If this is the case, then
  # flatten it as expected.
  newobj = {}
  if indicies == ['Property', 'Value']
    ret.each { |x|
      newobj[x['Property']] = x['Value']
    }
    [newobj]
  else
    ret
  end
end

