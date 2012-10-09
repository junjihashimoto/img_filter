#!/usr/bin/env perl
use utf8;
#use Safe;
use Tk;
use Tk::JPEG;
use Tk::PNG;
use Encode qw(decode encode);
#use Win32::Registry;

$top = MainWindow->new();

$w=$top->winfo("vrootwidth");
$h=$top->winfo("vrootheight");
$c=$top->Canvas(-width=>$w,-height=>$h);
$c->pack();

@imgs=glob "*.jpg *.bmp *.png */*.jpg */*.bmp */*.png */*/*.jpg */*/*.bmp */*/*.png";

sub photo_fit{
    my $p2=$top->Photo(-file=>shift);
    my $p =$top->Photo();

    my $ra=$w/$h;
    my $pa=$p2->width/$p2->height;

    if($ra>=$pa){
	$a=$h/$p2->height;
    }else{
	$a=$w/$p2->width;
    }

    if($a>=1){
	$p=$p2;
    }else{
	$p->copy($p2,-subsample=>1/$a);
    }
    $top->geometry(sprintf("%dx%d+0+0",$p->width,$p->height));
    $p;
}
sub setimage{
    $c->createImage(0,0,-image=>photo_fit(shift),-anchor=>nw);
}

$idx=0;

setimage($imgs[0]) if(@imgs > 0);

$top->bind("<KeyPress-q>",\&exit);
$top->bind("<KeyPress-n>",
	   sub {
	       if( $idx + 1 <@imgs){
		   setimage($imgs[++$idx]);
	       }
	   });

$top->bind("<KeyPress-p>",
	   sub {
	       if( $idx > 0 ){
		   setimage($imgs[--$idx]);
	       }
	   });


MainLoop();
