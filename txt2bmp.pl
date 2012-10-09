#!/usr/bin/env perl
use lib '.';
use Bitmap;

my $bm=new Bitmap;
$bm->load($ARGV[0]);

open IN,"<".$ARGV[1];
bmap {
  (hex($1),hex($2),hex($3)) if(<IN> =~ /(...)(...)(...)/);
} $bm;

$bm->save($ARGV[2]);
