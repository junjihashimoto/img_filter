#!/usr/bin/env perl

use lib '.';
use Bitmap;

my $bm=new Bitmap;
$bm->load($ARGV[0]);
$bm->for_each(sub{
		package Bitmap;
		printf "%03x%03x%03x\n",pix($x,$y);
	      });

