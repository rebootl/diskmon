#!/usr/bin/perl
#
{
  package MyWebServer;

  use strict;
  use warnings;

  use HTTP::Server::Simple::CGI;
  use base qw(HTTP::Server::Simple::CGI);
  use FindBin qw( $Script $Bin $RealBin );
  # (use this to find modules in script dir!!)
  use lib $RealBin;
  use Template;
  use JSON;

  # (debug)
  use Data::Dumper;

  use MyConfig;
  my $config = $MyConfig::config;

  my %dispatch = (
  '/' => \&myresp,
  #'/example_form' => \&myresp,
  #'/' => \&resp_hello,
  # ...
  );

  my $tt  = Template->new({
    INCLUDE_PATH => "$Bin",
    #INCLUDE_PATH => "$Bin/templates",
  });

  sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $path = $cgi->path_info();
    my $handler = $dispatch{$path}; # ref. to function

    if (ref($handler) eq "CODE") {
      print "HTTP/1.0 200 OK\r\n";
      $handler->($self, $cgi);

    } else {
      print "HTTP/1.0 404 Not found\r\n";
      print $cgi->header,
      $cgi->start_html('Not found'),
      $cgi->h1('Not found'),
      $cgi->end_html;
    }
  }

  sub load_usage2 {
    my $self = shift;
    open FH, '<', $config->{usage}->{data_file}
      or die "Could not open file '$config->{usage}->{data_file}' $!";
    # improved data struct.:
    # $usage = {
    #   /dev/sda => {
    #     dates = [ date1, date2, date3, date4, ... ],
    #     parts = {
    #       '/' = {
    #         size = [ s1, s2, s3, s4, ... ],
    #         usage = [ d1, d2, d3, d4, ... ]
    #        },
    #       '/var' = {
    #         ...
    #        }
    #     }
    #   ...
    #   }
    # }
    my $usage = {};
    foreach (@{$config->{disks}}) {
      ${$usage}{$_} = {
        dates => [],
        parts => {},
      };
    }
    while (my $row = <FH>) {
      chomp $row;
      foreach (@{$config->{disks}}) {
        my @parts = ();
        my @dates = ();
        my $run = 0;
        my @tmp = split(/\|/, $row);
        if ($tmp[0] eq $_) {
          shift @tmp;
          push @{$usage->{$_}->{dates}}, shift @tmp;
          my %parts = ();
          while (scalar @tmp >= 2) {
            if ($run == 0) {
              ${$usage}{$_}{parts} = [
                name => shift @tmp,
                size => [ shift @tmp ],
                used => [ shift @tmp ],
              ];
            }
          }
          #  } else {
          #    push @{$usage->{$_}->{shift @tmp}->{size}}, shift @tmp;
          #    push @{$usage->{$_}->{shift @tmp}->{usage}}, shift @tmp;
          #  }
          #}
          #@{$newhash}{parts} = \@parts;
          #push @{$usage->{$_}}, $newhash;
        }
      }
    }
    print STDERR Dumper($usage);
    close FH;
    return $usage;
  }

  sub load_usage {
    my $self = shift;
    open FH, '<', $config->{usage}->{data_file}
      or die "Could not open file '$config->{usage}->{data_file}' $!";
    # $usage = {
    #   /dev/sda =>
    #     [ { date => <d1>,
    #         parts => [
    #          { part => <p1>,
    #            size => <s1>,
    #            used => <u1> },
    #           ..,
    #     ],
    #     ..
    #   }
    # }
    my $usage = {};
    foreach (@{$config->{disks}}) {
      @{$usage}{$_} = [];
    }
    while (my $row = <FH>) {
      chomp $row;
      foreach (@{$config->{disks}}) {
        my @tmp = split(/\|/, $row);
        if ($tmp[0] eq $_) {
          shift @tmp;
          my $newhash = { date => shift @tmp };
          my @parts = ();
          while (scalar @tmp >= 2) {
            push @parts, {
              part => shift @tmp,
              size => shift @tmp,
              used => shift @tmp,
            };
          }
          @{$newhash}{parts} = \@parts;
          push @{$usage->{$_}}, $newhash;
        }
      }
    }
    #print STDERR Dumper($usage);
    close FH;
    return $usage;
  }

  sub load_status {
    my $self = shift;
    # -> maybe use try here
    open FH, '<', $config->{status}->{data_file}
      or die "Could not open file '$config->{status}->{data_file}' $!";
    # data structure:
    # $status = {
    #   /dev/sda => [
    #     { date => ..,
    #       fields => [
    #         { value => <v1>,
    #           limit => <l1> },
    #           ..
    #       ]
    #     },
    #     ..
    #   ],
    #   /dev/sdb => [
    #     ..
    #   ]
    # }
    my $status = {};
    foreach (@{$config->{disks}}) {
      @{$status}{$_} = [];
    }
    while (my $row = <FH>) {
      chomp $row;
      foreach (@{$config->{disks}}) {
        my @tmp = split(/\|/, $row);
        if ($tmp[0] eq $_) {
          shift @tmp;
          my $newhash = { date => shift @tmp };
          my @fields = ();
          foreach (@{$config->{status}->{fields}}) {
            my $value = shift @tmp;
            my $alert = '';
            if ($value eq "no data found") {
              $alert = 'OK';
            } else {
              if ($value >= $_->{'limit'}) {
                $alert = 'ALERT';
              } else {
                $alert = 'OK';
              }
            }
            push @fields, {
              value => $value,
              alert => $alert
            };
            @{$newhash}{fields} = \@fields;
          }
          #print STDERR Dumper($newhash);
          push @{$status->{$_}}, $newhash;
        }
      }
      #print STDERR Dumper($status);
    }
    close FH;
    return $status;
  }

  sub myresp {
    my $self = shift;
    my $cgi = shift;
    return if !ref $cgi;

    my $status = $self->load_status();
    my $usage = $self->load_usage();
    my $usage2 = $self->load_usage2();
    my $usage_json = encode_json $usage;

    # assemble the data diskwise... :(
    # $data = [
    #   disk1 => {
    #     data1 ...
    #   },
    #   disk2 => {
    #     data...
    #   }
    # ]
    # my %data = ();
    # foreach (@{$config->{disks}}) {
    #   my @parts = ();
    #   my $diskdata = {
    #     status => $status->{$_},
    #     usage => {
    #       parts => \@parts,
    #       json => encode_json $usage->{$_}
    #     }
    #   };
    #   $data{$_} = $diskdata;
    # }
    #print STDERR Dumper(\%data);

    my $res;
    my $out = $cgi->header();
    $tt->process(
    "mytemplate.html.tt",
    {
      # disks => $config->{disks},
      # result => $res,
      # config => $config,
      # status => $status,
      # usage_json => $usage_json,
      # data => \%data,
    },
    \$out,
    ) or die $tt->error;
    print $out;
  }
}

# start the server on port 8080
my $pid = MyWebServer->new(6001)->background();
print "Use 'kill $pid' to stop server.\n";
