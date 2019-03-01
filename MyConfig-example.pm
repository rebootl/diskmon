#
#
#
package MyConfig;

use strict;
use warnings;

# Attention: Especially for status, the fields order matter for the file it's
# written to !!!
# That means it's not possible to change the field order as long as an existing
# data file is used.

# list of blockdevices w/ respective parameters
our @config = (
  {
    name => '/dev/sda',
    status => {
      smartctl_opt => '-d sat',
      data_file => 'statusdat1.txt',
      fields => [
        {
          label => 'Reall. Sect. Ct.',
          name => 'Reallocated_Sector_Ct',
          limit => 5
        },
        {
          label => 'Curr. Pend. Sect.',
          name => 'Current_Pending_Sector',
          limit => 5
        },
        {
          label => 'Airflow Temp. Cel.',
          name => 'Airflow_Temperature_Cel',
          limit => 38
        },
      ]
    },
    usage => {
      data_file => 'usagedat1.txt',
      parts => [
        {
          dev => '/dev/sda1',
          mountpoint => '/',
          color => '#cc2400'
        },
        {
          dev => '/dev/sda2',
          mountpoint => '/var',
          color => '#166f20' #34a811'
        },
        {
          dev => '/dev/sda4',
          mountpoint => '/home',
          color => '#1133a8'
        },
      ]
    },
  },
);

1;
