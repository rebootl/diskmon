#
#
#
package MyConfig;

use strict;
use warnings;

our $config = {
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

our $config2 = [
  {
    name => '/dev/sda'
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
      data_file => 'usagedat1.txt',
      parts => [ '/root', '/var', '/home' ]
    },
  },
  {
    name => '/dev/sdb'
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
]

1;
