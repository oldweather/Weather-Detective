#!/usr/bin/perl 

# Convert from local time to UTC, and from original units to 
#  IMMA units.

use strict;
use warnings;
#use FindBin;
#use MarineOb::IMMA;
use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxeimb fxmmmb fwbpgv fxtftc ix32dd ixdcdd fxbfms
     fwbptf fwbptc);
#use Data::Dumper;
use Scalar::Util qw(looks_like_number);

open(DIN,"<../interpolate_positions/interpolated.csv") or die;
open(DOUT,">new_units.csv");
while(my $Line = <DIN>) {
    chomp($Line);
    if($Line =~ /V1/) { next; }
    $Line =~ s/\"//g;
    my @Fields = split /,/,$Line;
    my $Converted=convert_units(@Fields);
    if(!defined($Converted)) { next; }
    print_ob(\*DOUT,$Converted);
    #die;
}
close(DIN);
close(DOUT);

sub convert_units {
    my @Original=(@_);

   # Bail if missing position
    if($Original[10] eq 'NA' || $Original[11] eq 'NA') { return(); }

  # Time to UTC
    my $Year=substr($Original[2],0,4);
    my $Month=substr($Original[2],5,2);
    my $Day=substr($Original[2],8,2);
    my $Hour=substr($Original[2],11,2);
    #print "$Year $Month $Day $Hour\n";
    my $elon = $Original[11];
    #print "$elon\n";
    if($elon eq 'NA') { return(); }
    if ( $elon < 0 ) { $elon += 360; }
    unless(looks_like_number($elon)) {
        die "Bad longitude $elon";
    }
    my ( $uhr, $udy ) = rxltut(
	$Hour * 100,
	ixdtnd( $Day, $Month, $Year ),
	$elon * 100
    );
    $Hour = $uhr / 100;
    ( $Day, $Month, $Year ) = rxnddt($udy);
    #print "$Year $Month $Day $Hour\n";
    push @Original,($Year,$Month,$Day,$Hour);

   # Temperature to C
    my $Temperature='NA';
    if($Original[4] ne 'NA') {
	$Temperature=fxtftc($Original[4]);
    } 
    #print "$Original[4] $Temperature\n";
    push @Original,$Temperature;

   # Pressure to hPa
    my $Pressure='NA';
    if($Original[5] ne 'NA' && $Original[4] ne 'NA') {
        if($Original[5]>2000) { $Original[5]/=100; }
	if($Original[5]<35 && $Original[5]>25) {
	    $Pressure=fxeimb($Original[5]+fwbptf($Original[5],$Original[4]));
        }
        elsif($Original[5]<800 && $Original[5]>700) {
	    $Pressure=fxmmmb($Original[5]+fwbptc($Original[5],$Temperature));
        }
        else {
	    warn "Unknown pressure value $Original[5]";
	}
        # Gravity correction
        if($Pressure ne 'NA') {
           $Pressure += fwbpgv( $Pressure, $Original[10], 2 );
        }
    }
    #print "$Original[5] $Pressure\n";
    push @Original,$Pressure;

    # Wind to m/s
    my $WindSpeed;
    if($Original[7] ne 'NA') {
	$WindSpeed=fxbfms($Original[7]);
    } 
    push @Original,$WindSpeed;
    
    return(\@Original);
}

sub print_ob {
    my $Dout = shift;
    my $Converted = shift;
    print $Dout "$Converted->[0]";
    for(my $i=1;$i<scalar(@{$Converted});$i++) {
        unless(defined($Converted->[$i])) { $Converted->[$i]='NA'; }
	print $Dout ",$Converted->[$i]";
    }
    print $Dout "\n";
}
