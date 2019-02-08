#!/usr/bin/perl
#
use strict;
use warnings;
use FindBin qw( $Script $Bin $RealBin );
use lib $RealBin;
use POSIX qw(strftime);

# -> import w/ quote ?
use MyConfig;
my $config = $MyConfig::config;

sub scan_status {
  my $d = shift;
  my $result = `sudo smartctl -A $d`;
  my $data = "";
  foreach my $field (@{$config->{status}->{fields}}) {
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
  #my $identi = $d;
  #$identi =~ s@/@@g;
  my $timestamp = strftime "%c", localtime;
  open FH, '>>', $config->{status}->{data_file};
  print FH $d . "|" . $timestamp . $data . "\n";
  close FH;
  print "Written data to: " . $config->{status}->{data_file} . "\n";
}

sub scan_usage {
  my $d = shift;
  my $res = `df`;
  my $data = "";
  foreach (split(/\n/, $res)) {
    if (/^$d/) {
      #print $_ . "\n";
      my @tmp = split(' ', $_);
      my $datline = "|" . $tmp[5] . "|" . $tmp[1] . "|" . $tmp[2];
      $data .= $datline;
    }
  }
  my $timestamp = strftime "%c", localtime;
  #print $d . "|" . $timestamp . $data . "\n";
  open FH, '>>', $config->{usage}->{data_file};
  print FH $d . "|" . $timestamp . $data . "\n";
  close FH;
  print "Written data to: " . $config->{usage}->{data_file} . "\n";
}

foreach my $d (@{$config->{disks}}) {
  print $d;
  if (-b $d) {
    print " BLOCKDEV\n";
    scan_status($d);
    scan_usage($d);
    #write_data($d);
  } else {
    print " NO BLOCKDEV (skipped)\n";
  }
}
