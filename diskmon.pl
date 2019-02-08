#!/usr/bin/perl
#
use strict;
use warnings;
use FindBin qw( $Script $Bin $RealBin );
use lib $RealBin;
use POSIX qw(strftime);

# -> import w/ quote ?
use MyConfig;
my @config = @MyConfig::config;

sub scan_status {
  my $dev = shift;
  my $status = $dev->{status};
  my $result = `sudo smartctl -A $dev->{name}`;
  my $data = "";
  foreach my $field (@{$status->{fields}}) {
    #print STDERR $field->{name};
    my $found = 0;
    foreach (split(/\n/, $result)) {
      if (/$field->{name}/) {
        #print $_ . "\n";
        print " FOUND " . $field->{name} . "\n";
        my @tmp = split(' ', $_);
        $data .= "|" . $tmp[9];
        $found = 1;
        last;
      }
    }
    if ($found eq 0) {
      print " NOT FOUND " . $field->{name} . "\n";
      $data .= "|no data found";
    }
  }
  #print $data . "\n";
  #my $identi = $d;
  #$identi =~ s@/@@g;
  my $timestamp = strftime "%c", localtime;
  open FH, '>>', $status->{data_file};
  print FH $timestamp . $data . "\n";
  close FH;
  print "Written data to: " . $status->{data_file} . "\n";
}

sub scan_usage {
  my $dev = shift;
  my $res = `df`;
  my $data = "";
  foreach (split(/\n/, $res)) {
    foreach my $part (@{$dev->{usage}->{parts}}) {
      if (/^$part/) {
        #print $_ . "\n";
        my @tmp = split(' ', $_);
        my $datline = "|" . $tmp[5] . "|" . $tmp[1] . "|" . $tmp[2];
        $data .= $datline;
      }
    }
  }
  #print $data . "\n";
  my $timestamp = strftime "%c", localtime;
  #print $d . "|" . $timestamp . $data . "\n";
  open FH, '>>', $dev->{usage}->{data_file};
  print FH $timestamp . $data . "\n";
  close FH;
  print "Written data to: " . $dev->{usage}->{data_file} . "\n";
}

foreach my $dev (@config) {
  print $dev->{name};
  if (-b $dev->{name}) {
    print " BLOCKDEV\n";
    scan_status($dev);
    scan_usage($dev);
  } else {
    print " NO BLOCKDEV (skipped)\n";
  }
}
