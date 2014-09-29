#!/usr/bin/perl

# Process digitised logbook data from Cook's Adventure obs into
#  IMMA records.

use strict;
use warnings;
use MarineOb::IMMA;

my %Imma;
open(DIN,"<../convert_units/new_units.csv") or die;
while(my $Line = <DIN>) {
    chomp($Line);
    $Line =~ s/\"//g;
    my @Fields = split /,/,$Line;

    my $Ob = new MarineOb::IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    $Ob->{YR} = $Fields[12];
    $Ob->{MO} = $Fields[13];
    $Ob->{DY} = $Fields[14];
    $Ob->{HR} = $Fields[15];
    $Ob->{LAT} = $Fields[10];
    $Ob->{LON} = $Fields[11];
    $Ob->{AT} = $Fields[16];
    $Ob->{SLP} = $Fields[17];
    $Ob->{W} = $Fields[18];
    $Ob->{ID} = $Fields[3];
    if(length($Ob->{ID})>9) { $Ob->{ID}=substr($Ob->{ID},0,9); }
    foreach my $Var(qw(YR MO DY HR LAT LON AT SLP W ID)) {
	if($Ob->{$Var} eq 'NA') { $Ob->{$Var}=undef; }
    }
    push @{$Imma{$Fields[3]}},$Ob;
}
close(DIN);

foreach my $Ship (keys(%Imma)) {
    my $Fn = $Ship;
    $Fn =~ s/\s/_/g;
    open(DOUT,">../../imma/$Fn") or die "Can't open output for $Fn";
    @{$Imma{$Ship}} = sort imma_by_date @{$Imma{$Ship}}; 
    foreach my $Ob (@{$Imma{$Ship}}) {
	$Ob->write(\*DOUT);
    }
    close(DOUT);
}

sub imma_by_date {
    return($a->{YR} <=> $b->{YR} ||
           $a->{MO} <=> $b->{MO} ||
           $a->{DY} <=> $b->{DY} ||
	   $a->{HR} <=> $b->{HR});
}
