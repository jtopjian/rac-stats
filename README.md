# RAC Stat Scripts

The following is a collection of scripts to help collect usage information in RAC.

## Requirements

  * `openrc` file with admin privileges
  * `nova` command
  * `ascii_charts` ruby gem

## Files

### prettytable_to_array.rb

Helper function to convert the `prettytable` output of OpenStack commands into a workable data structure.

### inventory.rb

Loops through all instances and creates an `instances.csv` file. You can then write scripts that use this information.

Running `inventory.rb` multiple times will add new instances and remove deleted instances from `instances.csv`.

### histo.rb

A sample script that utilizes `instances.csv`. In this case, it prints a histogram of the relationship between users and the number of instances they have running.
