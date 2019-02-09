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

  # sub load_status {
  #   my $self = shift;
  #   # -> maybe use try here
  #   open FH, '<', $config->{status}->{data_file}
  #     or die "Could not open file '$config->{status}->{data_file}' $!";
  #   # data structure:
  #   # $status = {
  #   #   /dev/sda => [
  #   #     { date => ..,
  #   #       fields => [
  #   #         { value => <v1>,
  #   #           limit => <l1> },
  #   #           ..
  #   #       ]
  #   #     },
  #   #     ..
  #   #   ],
  #   #   /dev/sdb => [
  #   #     ..
  #   #   ]
  #   # }
  #   my $status = {};
  #   foreach (@{$config->{disks}}) {
  #     @{$status}{$_} = [];
  #   }
  #   while (my $row = <FH>) {
  #     chomp $row;
  #     foreach (@{$config->{disks}}) {
  #       my @tmp = split(/\|/, $row);
  #       if ($tmp[0] eq $_) {
  #         shift @tmp;
  #         my $newhash = { date => shift @tmp };
  #         my @fields = ();
  #         foreach (@{$config->{status}->{fields}}) {
  #           my $value = shift @tmp;
  #           my $alert = '';
  #           if ($value eq "no data found") {
  #             $alert = 'OK';
  #           } else {
  #             if ($value >= $_->{'limit'}) {
  #               $alert = 'ALERT';
  #             } else {
  #               $alert = 'OK';
  #             }
  #           }
  #           push @fields, {
  #             value => $value,
  #             alert => $alert
  #           };
  #           @{$newhash}{fields} = \@fields;
  #         }
  #         #print STDERR Dumper($newhash);
  #         push @{$status->{$_}}, $newhash;
  #       }
  #     }
  #     #print STDERR Dumper($status);
  #   }
  #   close FH;
  #   return $status;
  # }

  sub load_usage {
    my $self = shift;
    my $dev = shift;
    print STDERR Dumper($dev);
    open FH, '<', $dev->{usage}->{data_file}
      or die "Could not open file '$dev->{usage}->{data_file}' $!";
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
    while (my $row = <FH>) {
      chomp $row;
      my @tmp = split(/\|/, $row);
    }
  }

  sub myresp {
    my $self = shift;
    my $cgi = shift;
    return if !ref $cgi;

    # my $status = $self->load_status();

    my @data = ();
    foreach my $dev (@config) {
      #print STDERR Dumper($dev);
      my $usage = $self->load_usage($dev);
      #my $status = load_status($status);
      push @data, {
        usage => $usage,
        #status => $status,
      };
    }

    my $res;
    my $out = $cgi->header();
    $tt->process(
    "mytemplate.html.tt",
    {
      config => $config,
      data => \@data,
      # -> data json
    },
    \$out,
    ) or die $tt->error;
    print $out;
  }
}

# start the server on port 8080
my $pid = MyWebServer->new(6001)->background();
print "Use 'kill $pid' to stop server.\n";
