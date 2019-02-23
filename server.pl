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
  my @config = @MyConfig::config;

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

  sub load_usage {
    my $self = shift;
    my $dev = shift;
    #print STDERR Dumper($dev);
    # -> try block here would kinda make sense
    open FH, '<', $dev->{usage}->{data_file} or return {};
      #print STDERR "Could not open file '$dev->{usage}->{data_file}' $!";
      #return {};
    #}
      #or die "Could not open file '$dev->{usage}->{data_file}' $!";
    # improved data struct.:
    # $usage = {
    #     dates = [ date1, date2, date3, date4, ... ],
    #     parts = [
    #       {
    #         name = '/',
    #         size = [ s1, s2, s3, s4, ... ],
    #         usage = [ d1, d2, d3, d4, ... ]
    #       },
    #       ...
    #     ]
    # }
    # (preparing data structure)
    my @dates = ();
    my @parts = ();
    foreach (@{$dev->{usage}->{parts}}) {
      push @parts, {
        name => $_->{mountpoint},
        size => [],
        usage => [],
        color => $_->{color}
      };
    }
    while (my $row = <FH>) {
      chomp $row;
      my @tmp = split(/\|/, $row);
      push @dates, shift @tmp;
      while (scalar @tmp >= 3) {
        foreach (@parts) {
          last if (scalar @tmp == 0);
          if ($tmp[0] eq $_->{name}) {
            shift @tmp;
            push @{$_->{size}}, shift @tmp;
            push @{$_->{usage}}, shift @tmp;
            next;
          }
        }
      }
    }
    close FH;
    my $usage = {
      dates => \@dates,
      parts => \@parts
    };
    #print STDERR Dumper($usage);
    return $usage;
  }

  sub load_status {
    my $self = shift;
    my $dev = shift;
    # -> maybe use try here
    open FH, '<', $dev->{status}->{data_file}
      or return {};
      #or die "Could not open file '$config->{status}->{data_file}' $!";
    # data structure:
    # $status = [
    #   { date => ..,
    #     fields => [
    #       { value => <v1>,
    #         limit => <l1> },
    #          ..
    #     ]
    #   },
    #   ..
    # ]
    my @status = ();
    while (my $row = <FH>) {
      chomp $row;
      my @tmp = split(/\|/, $row);
      my $newhash = {
        date => shift @tmp,
        fields => []
      };
      foreach (@{$dev->{status}->{fields}}) {
        my @fields = ();
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
        push @{$newhash->{fields}}, {
          label => $_->{'label'},
          limit => $_->{'limit'},
          value => $value,
          alert => $alert
        };
        #push @{$newhash}{fields}, \@fields;
      }
      #print STDERR Dumper($newhash);
      push @status, $newhash;
    }
    close FH;
    #print STDERR Dumper(\@status);
    return \@status;
  }

  sub myresp {
    my $self = shift;
    my $cgi = shift;
    return if !ref $cgi;

    my $n_stat_entr = 5;

    my @data = ();
    my @data_json = ();
    foreach my $dev (@config) {
      #print STDERR Dumper($dev);
      my $usage = $self->load_usage($dev);
      my $status = $self->load_status($dev);

      my @status = reverse @{$status};
      my @status_part = @status[0..$n_stat_entr-1];
      #print STDERR Dumper(\@status);

      push @data, {
        name => $dev->{'name'},
        usage => $usage,
        status => \@status_part
      };
      push @data_json, {
        name => $dev->{'name'},
        usage => $usage
      };
    }
    #print STDERR Dumper(@data);

    my $res;
    my $out = $cgi->header();
    $tt->process(
    "mytemplate.html.tt",
    {
      config => \@config,
      data => \@data,
      data_json => encode_json \@data_json,
    },
    \$out,
    ) or die $tt->error;
    print $out;
  }
}

# start the server on port 8080
my $pid = MyWebServer->new(6001)->background();
print "Use 'kill $pid' to stop server.\n";
