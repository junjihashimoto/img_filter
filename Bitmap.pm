package Bitmap;
use Exporter;
use integer;
@ISA = (Exporter);
@EXPORT = qw(
	     bmap
	     bforeach
	     bs
	     amap
	     );

sub new{
    my $class=shift;
    return bless {}, $class;
}

sub init{
    my $self  =shift;

    $self->{width} =shift;
    $self->{height}=shift;
    
    my $w=$self->{width}*3;
    $self->{wlen}              =
	($w&3) == 0 ?
	$w :
	(($w>>2)<<2) + 4;
    
    $self->{bit_per_pix} = 24;

    $self->{compression_mode} = 0;

    $self->{offset}=54;
    my $sizeImage=$w*$self->{height};
    $self->{size}= $self->{offset}+$sizeImage;


    $self->{dat}=
	pack("a2". #BM
	     "V".  #size
	     "x2x2". #0,0
	     "V".  #offset
	     "V".  #biSize 40
	     "V".  #width
	     "V".  #height
	     "v".  #planes 1
	     "v".  #bitcount
	     "V".  #Compression
	     "V".  #image data size
	     "x2".  #0
	     "x2".  #0
	     "x2".  #0
	     "x2".  #0
	     "x$sizeImage"
	     ,
	     "BM",
	     $self->{size},
#	     0,0,
	     $self->{offset},
	     40,
	     $self->{width},
	     $self->{height},
	     1,
	     $self->{bit_per_pix},
	     $self->{compression_mode},
	     $sizeImage
#	     0,0,0,0
	     );
}

sub load{
    my $self=shift;
    my $file=shift;
    my $dat;
    local *IN;
    local $/ = undef;

    if(defined $file){
	open IN,"<$file";
	binmode IN;
	$self->{dat}=<IN>;
	close IN;
    }else{
	binmode STDIN;
	$self->{dat}=<STDIN>;
    }

    substr($self->{dat},0,2)=="BM" or die;
    
    $self->{width}             =unpack("V",substr($self->{dat},18,4));
    my $w=$self->{width}*3;
    $self->{wlen}              =
	($w&3) == 0 ?
	$w :
	(($w>>2)<<2) + 4;
    $self->{height}            =unpack("V",substr($self->{dat},22,4));
    $self->{bit_per_pix}       =unpack("v",substr($self->{dat},28,2));

    $self->{bit_per_pix} == 24 or die;
    
    $self->{compression_mode}  =unpack("V",substr($self->{dat},30,4));
    $self->{compression_mode} == 0 or die;

    $self->{offset}            =unpack("V",substr($self->{dat},10,4));
}
sub save{
    my $self=shift;
    my $file=shift;
    local *OUT;
    if(defined $file){
	open OUT,">$file";
	binmode OUT;
	print OUT $self->{dat};
	close OUT;
    }else{
	binmode STDOUT;
	print STDOUT $self->{dat};
    }
}
sub get{
    my $self=shift;
    my $x   =shift;
    my $y   =shift;
    my $offset=
	$self->{offset}+
	($self->{height} -1 -$y)*$self->{wlen} +
	3*$x;
    reverse(unpack("CCC",substr($self->{dat},$offset,3)));
}

sub getc{
    my $self=shift;
    my $x   =shift;
    my $y   =shift;
    my $c   =shift;
    my $offset=
	$self->{offset}+
	($self->{height} -1 -$y)*$self->{wlen} +
	3*$x ;
    $offset+=2 if($c==0);
    $offset+=1 if($c==1);
#    $offset=0 if($c==2);
    
    unpack("C",substr($self->{dat},$offset,1));
}

sub getAry{
    local $self   =shift;
    local $x;
    local $y;
    local ($r,$g,$b);
    local $width=$self->{width};
    local $height=$self->{height};
    local $offset=$self->{offset};
    local $t;
    local $wlen=$self->{wlen};
    local *rdat=\$self->{dat};
    local $dat=$self->{dat};
    my $ary;
    for $y (0..($height-1)){
	for $x (0..($width-1)){
	    $ary->[$x][$y]=[pix($x,$y)];
	}
    }
    $ary;
}

sub setAry{
    local $self  =shift;
    local $ary   =shift;
    local $x;
    local $y;
    local ($r,$g,$b);
    local $width=$self->{width};
    local $height=$self->{height};
    local $offset=$self->{offset};
    local $t;
    local $wlen=$self->{wlen};
    local *rdat=\$self->{dat};
    for $y (0..($height-1)){
	$t= $offset + ($height -1 -$y)*$wlen;
	for $x (0..($width-1)){
	    substr($rdat,$t,3)=pack("CCC",reverse(@{$ary->[$x][$y]}));
	    $t+=3;
	}
    }
    return 0;
}


sub set{
    my $self=shift;
    my $x   =shift;
    my $y   =shift;
    my @v   =@_;
    my $offset=
	$self->{offset}+
	($self->{height} -1 -$y)*$self->{wlen} +
	3*$x;
    substr($self->{dat},$offset,3)=
	pack("CCC",$v[2],$v[1],$v[0]);
}

sub setc{
    my $self=shift;
    my $x   =shift;
    my $y   =shift;
    my $c   =shift;
    my @v   =@_;
    my $offset=
	$self->{offset}+
	($self->{height} -1 -$y)*$self->{wlen} +
	3*$x;
    $offset+=2 if($c==0);
    $offset+=1 if($c==1);
#    $offset=0 if($c==2);

    substr($self->{dat},$offset,1)=pack("C",$v[0]);
}


# sub pix{
#     reverse(unpack("CCC",substr($rdat,
# 				$offset + ($height -1 -$_[1])*$wlen + 3*$_[0],
# 				3
# 				)
# 		   )
# 	    );
# }

sub pix{
    reverse(unpack("CCC",substr($rdat,
				$pixoffset - $_[1]*$wlen + 3*$_[0],
				3
				)
		   )
	    );
}

sub filter($&){
    local $self   =shift;
    local *func   =shift;
    local $x;
    local $y;
    local ($r,$g,$b);
    local $width=$self->{width};
    local $height=$self->{height};
    local $offset=$self->{offset};
    local $t;
    local $wlen=$self->{wlen};
    local *rdat=\$self->{dat};
    local $dat=$self->{dat};
    local $pixoffset=$offset + ($height -1)*$wlen;

    for $y (0..($height-1)){
	$t= $pixoffset-$y*$wlen;
	for $x (0..($width-1)){
	    substr($dat,$t,3)=pack("CCC",reverse(func()));
	    $t+=3;
	}
    }
    $self->{dat}=$dat;
    return 0;
}

sub filterN($$&){
    local $self   =shift;
    local $step   =shift;
    local *func   =shift;
    local $x;
    local $y;
    local ($r,$g,$b);
    local $width=$self->{width};
    local $height=$self->{height};
    local $offset=$self->{offset};
    local $t;
    local $wlen=$self->{wlen};
    local *rdat=\$self->{dat};
    local $dat=$self->{dat};
    local $pixoffset=$offset + ($height -1)*$wlen;

    for $y (0..($height-1)){
	$t= $pixoffset-$y*$wlen;
	for ($x=0;$x<$width;$x+=$step){
	    for my $i(func()){
		substr($dat,$t,3)=pack("CCC",reverse(@{$i}));
		$t+=3;
	    }
	}
    }
    $self->{dat}=$dat;
    return 0;
}


sub for_each($&){
    local $self   =shift;
    local *func   =shift;
    local $x;
    local $y;
    local ($r,$g,$b);
    local $width=$self->{width};
    local $height=$self->{height};
    local $offset=$self->{offset};
    local $t;
    local $wlen=$self->{wlen};
    local *rdat=\$self->{dat};
    local $pixoffset=$offset + ($height -1)*$wlen;


    for $y (0..($height-1)){
	$t= $pixoffset-$y*$wlen;
	for $x (0..($width-1)){
	    func();
	    $t+=3;
	}
    }
    return 0;
}

sub bmap(&$){
  local *func   = shift;
  my    $self   = shift;
  my    $caller = caller;
  local *rdat   = \$self->{dat};
  local(*{$caller."::x"})      = \my $x;
  local(*{$caller."::y"})      = \my $y;
  local(*{$caller."::width"})  = \$self->{width};
  local(*{$caller."::height"}) = \$self->{height};
  my    $width                 = $self->{width};
  my    $height                = $self->{height};
  my    $t;
  my    $wlen                  = $self->{wlen};
  my    $dat                   = $self->{dat};
  my    $pixoffset             = $self->{offset} + ($height -1)*$wlen;
  local(*{$caller."::pix"}) = sub {
    reverse(unpack("CCC",substr($rdat,
				$pixoffset - $_[1]*$wlen + 3*$_[0],
				3
			       )
		  )
	    )
    };
  local(*{$caller."::cpix"}) = sub {
    reverse(unpack("CCC",substr($rdat,$t,3)))
    };
  for my $ty (0..($height-1)) {
    $y = $ty;
    $t = $pixoffset-$y*$wlen;
    for my $tx (0..($width-1)) {
      $x = $tx;
      substr($dat,$t,3)=pack("CCC",reverse(func()));
      $t += 3;
    }
  }

  $self->{dat}=$dat;
  $self;
}

sub bs(&){
  local *func   = shift;
  my    $self   = new Bitmap;
  my    $caller = caller;
  $self->load;
  local *rdat   = \$self->{dat};
  local(*{$caller."::c"})      = \my $c;
  local(*{$caller."::x"})      = \my $x;
  local(*{$caller."::y"})      = \my $y;
  local(*{$caller."::r"})      = \my $r;
  local(*{$caller."::g"})      = \my $g;
  local(*{$caller."::b"})      = \my $b;
  local(*{$caller."::width"})  = \$self->{width};
  local(*{$caller."::height"}) = \$self->{height};
  my    $width                 = $self->{width};
  my    $height                = $self->{height};
  my    $t;
  my    $wlen                  = $self->{wlen};
  my    $dat                   = $self->{dat};
  my    $pixoffset             = $self->{offset} + ($height -1)*$wlen;
  local(*{$caller."::pix"}) = sub {
    reverse(unpack("CCC",substr($rdat,
				$pixoffset - $_[1]*$wlen + 3*$_[0],
				3
			       )
		  )
	    )
    };
  local(*{$caller."::cpix"}) = sub {
    reverse(unpack("CCC",substr($rdat,$t,3)))
    };
  for my $ty (0..($height-1)) {
    $y = $ty;
    $t = $pixoffset-$y*$wlen;
    for my $tx (0..($width-1)) {
      $x = $tx;
      ($r,$g,$b)=reverse(unpack("CCC",substr($rdat,$t,3)));
      $c=2;
      substr($dat,$t  ,1)=pack("C",func());
      $c=1;
      substr($dat,$t+1,1)=pack("C",func());
      $c=0;
      substr($dat,$t+2,1)=pack("C",func());
      $t += 3;
    }
  }

  $self->{dat}=$dat;
  $self->save;
  $self;
}

sub bforeach(&$){
  my    $caller = caller;
  local *func   = shift;
  my    $self   = shift;
  local *rdat   = \$self->{dat};
  local(*{$caller."::x"})      = \my $x;
  local(*{$caller."::y"})      = \my $y;
  local(*{$caller."::width"})  = \$self->{width};
  local(*{$caller."::height"}) = \$self->{height};
  my    $width                 = $self->{width};
  my    $height                = $self->{height};
  my    $t;
  my    $wlen                  = $self->{wlen};
  my    $pixoffset             = $self->{offset} + ($height -1)*$wlen;
  local(*{$caller."::pix"}) = sub {
    reverse(unpack("CCC",substr($rdat,
				$pixoffset - $_[1]*$wlen + 3*$_[0],
				3
			       )
		  )
	    )
    };
  local(*{$caller."::cpix"}) = sub { reverse(unpack("CCC",substr($rdat,$t,3))) };
  
  for my $ty (0..($height-1)) {
    $y = $ty;
    $t = $pixoffset-$y*$wlen;
    for my $tx (0..($width-1)) {
      $x = $tx;
      func();
      $t += 3;
    }
  }

  $self;
}

sub amap(&\@\@){
  local *fn     = shift;
  local *a0     = shift;
  local *a1     = shift;
  my    $size   = @a0;
  my    $caller = caller;
  local(*{$caller."::a"}) = \my $a;
  local(*{$caller."::b"}) = \my $b;
  my    @r;
  
  for(0..$#a0){
    $a=$a0[$_];
    $b=$a1[$_];
    push @r,fn();
  }
  @r;
}



1;

