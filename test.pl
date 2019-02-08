#!/usr/bin/perl


sub mysub {
  my $p1 = shift;
  # whatever
  print "Hi, p1: " . $p1 . "\n";
}


$subref = \&mysub;



$subref->("aaa");
