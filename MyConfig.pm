#
#
#
package MyConfig;

use strict;
use warnings;

our $config2 = {
  disks => [ '/dev/sda', '/dev/sdb' ],
  #data_file => 'diskdat.txt',
  status => {
    data_file => 'statusdat.txt',
    # the fields order matter for the file it's written to!!!
    fields => [
      {
        label => 'Reall. Sect. Ct.',
        name => 'Reallocated_Sector_Ct',
        limit => 5
      },
      {
        label => 'Airflow Temp. Cel.',
        name => 'Airflow_Temperature_Cel',
        limit => 37
      },
      {
        label => 'Curr. Pend. Sect.',
        name => 'Current_Pending_Sector',
        limit => 5
      },
    ]
  },
  usage => {
    data_file => 'usagedat.txt',
  }
};

# list of blockdevices w/ respective parameters
our @config = (
  {
    name => '/dev/sda',
    status => {
      data_file => 'statusdat1.txt',
      # the fields order matter for the file it's written to!!!
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
          limit => 37
        },
      ]
    },
    usage => {
      data_file => 'usagedat1.txt',
      parts => [
        {
          dev => '/dev/sda1',
          mountpoint => '/'
        },
        {
          dev => '/dev/sda2',
          mountpoint => '/var'
        },
        {
          dev => '/dev/sda4',
          mountpoint => '/home'
        },
      ]
    },
  },
  {
    name => '/dev/sdb',
    status => {
      data_file => 'statusdat2.txt',
      # the fields order matter for the file it's written to!!!
      fields => [
        {
          label => 'Reall. Sect. Ct.',
          name => 'Reallocated_Sector_Ct',
          limit => 5
        },
        {
          label => 'Airflow Temp. Cel.',
          name => 'Airflow_Temperature_Cel',
          limit => 37
        },
        {
          label => 'Curr. Pend. Sect.',
          name => 'Current_Pending_Sector',
          limit => 5
        },
      ]
    },
    usage => {
      data_file => 'usagedat2.txt',
      parts => [ '/root', '/var', '/home' ]
    },
  }
);

1;
