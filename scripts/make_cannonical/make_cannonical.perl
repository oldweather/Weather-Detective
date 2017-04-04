#!/usr/bin/perl 

# Make Cannonical records from each Weather Detective transcription
#  with two or more duplicate entries.

use strict;
use warnings;
#use FindBin;
#use MarineOb::IMMA;
#use MarineOb::lmrlib
#  qw(rxltut ixdtnd rxnddt fxeimb fwbpgv fxtftc ix32dd ixdcdd fxbfms);
#use Data::Dumper;

# Read in the processed ship names;
my %Names;
open(DIN,"<../get_ship_names/ship.names.csv") or die;
while(my $Line = <DIN>) {
    chomp($Line);
    if($Line =~ /IMAGE|concat/) { next; }
    $Line =~ s/\"//g;
    my @Fields = split /,/,$Line;
    $Names{$Fields[1]}=$Fields[13];
}
close(DIN);

# Read in the raw data
my %Raw;
open(DIN,"<../../raw_data/Exports/result_all.csv") or die;
while(my $Line = <DIN>) {
    if($Line =~ /IMAGE/) { next; }
    $Line =~ s/\"//g;
    my @Fields = split /,/,$Line;
    push @{$Raw{$Fields[0]}},\@Fields;
}
close(DIN);

my %Cannonical;

# Build connonical observations page by page.
sub process_page {
    my $url = shift;  # 
    unless(exists($Raw{$url})) {
	die "No such page $url";
    }
    my $Ship_name = 'Unknown';
    if(defined($Names{$url})) { $Ship_name = $Names{$url}; }
    #print "$Names{$url}\n";
    #unless($Ship_name eq 'Damascus') { return; }
    my @Transcriptions= @{$Raw{$url}};
    # Partition the data by hour
    my @Hours;
    foreach my $Transcription (@Transcriptions) {
      if(defined($Transcription->[2]) &&
         $Transcription->[2] =~ /\d\d\d\d/ &&
         defined($Transcription->[3]) &&
         $Transcription->[3] =~ /\d/ &&
         defined($Transcription->[4]) &&
         $Transcription->[4] =~ /\d/ &&
         defined($Transcription->[5]) &&
         $Transcription->[5] =~ /\d/) {
         push @Hours,sprintf "%04d/%02d/%02d:%02d",
            $Transcription->[2],
            $Transcription->[3],
            $Transcription->[4],
	 $Transcription->[5];
      }
      else {  push @Hours,undef; }
    }
    for(my $i=0;$i<scalar(@Hours)-1;$i++) {
	unless(defined($Hours[$i])) { next; }
        for(my $j=$i+1;$j<scalar(@Hours);$j++) {
           unless(defined($Hours[$j]) &&
		  $Hours[$j] eq $Hours[$i]) { next; }
           # At least two transcriptions for this page and hour
           unless(defined($Cannonical{$url}{$Hours[$i]})) {
              $Cannonical{$url}{$Hours[$i]}={ ship => $Ship_name};
	   }
           my $Cannon = $Cannonical{$url}{$Hours[$i]};
           # If the two transcriptions match for any variable, and
           # we don't already have a cannonical value for that variable,
           # update the cannonical variable with the shared value.
	   if(!defined($Cannon->{Thermometer}) &&
              defined($Transcriptions[$i][6]) &&
              defined($Transcriptions[$j][6]) &&
              $Transcriptions[$i][6] =~ /\w/ &&
              $Transcriptions[$i][6] ne 'NULL' &&
              $Transcriptions[$j][6] =~ /\w/ &&
              $Transcriptions[$j][6] ne 'NULL' &&
              $Transcriptions[$i][6] ==  $Transcriptions[$j][6]) {
	       $Cannon->{Thermometer} = $Transcriptions[$i][6];
           }
	   if(!defined($Cannon->{Barometer}) &&
              defined($Transcriptions[$i][7]) &&
              defined($Transcriptions[$j][7]) &&
              $Transcriptions[$i][7] =~ /\w/ &&
              $Transcriptions[$i][7] ne 'NULL' &&
              $Transcriptions[$j][7] =~ /\w/ &&
              $Transcriptions[$j][7] ne 'NULL' &&
              $Transcriptions[$i][7] ==  $Transcriptions[$j][7]) {
	       $Cannon->{Barometer} = $Transcriptions[$i][7];
           }
	   if(!defined($Cannon->{Wind_Direction}) &&
              defined($Transcriptions[$i][8]) &&
              defined($Transcriptions[$j][8]) &&
              $Transcriptions[$i][8] =~ /\w/ &&
              $Transcriptions[$i][8] ne 'NULL' &&
              $Transcriptions[$j][8] =~ /\w/ &&
              $Transcriptions[$j][8] ne 'NULL' &&
              $Transcriptions[$i][8] eq  $Transcriptions[$j][8]) {
	       $Cannon->{Wind_Direction} = $Transcriptions[$i][8];
           }
	   if(!defined($Cannon->{Wind_Force}) &&
              defined($Transcriptions[$i][9]) &&
              defined($Transcriptions[$j][9]) &&
              $Transcriptions[$i][9] =~ /\w/ &&
              $Transcriptions[$i][9] ne 'NULL' &&
              $Transcriptions[$j][9] =~ /\w/ &&
              $Transcriptions[$j][9] ne 'NULL' &&
              $Transcriptions[$i][9] ==  $Transcriptions[$j][9]) {
	       $Cannon->{Wind_Force} = $Transcriptions[$i][9];
           }
	   if(!defined($Cannon->{Latitude}) &&
              defined($Transcriptions[$i][10]) &&
              defined($Transcriptions[$j][10]) &&
              $Transcriptions[$i][10] =~ /\w/ &&
              $Transcriptions[$j][10] =~ /\w/ &&
              $Transcriptions[$i][10] ne 'NULL' &&
              $Transcriptions[$j][10] ne 'NULL' &&
              $Transcriptions[$i][10] ==  $Transcriptions[$j][10]) {
	       $Cannon->{Latitude} = $Transcriptions[$i][10];
           }
	   if(!defined($Cannon->{Longitude}) &&
              defined($Transcriptions[$i][11]) &&
              defined($Transcriptions[$j][11]) &&
              $Transcriptions[$i][11] =~ /\w/ &&
              $Transcriptions[$j][11] =~ /\w/ &&
              $Transcriptions[$i][11] ne 'NULL' &&
              $Transcriptions[$j][11] ne 'NULL' &&
              $Transcriptions[$i][11] ==  $Transcriptions[$j][11]) {
	       $Cannon->{Longitude} = $Transcriptions[$i][11];
           }
	}
    }
}

foreach my $url (keys(%Raw)) {
    #print "$url\n";
    process_page($url);
    #if(scalar(keys(%Cannonical))>1) { last; }
}

foreach my $url (sort(keys(%Cannonical))) {
    foreach my $Hour (sort(keys(%{$Cannonical{$url}}))) {
       printf "%s,%s,%s",$url,$Hour,
       $Cannonical{$url}{$Hour}{ship};
       foreach my $Var (qw(Thermometer Barometer Wind_Direction
                           Wind_Force Latitude Longitude)) {
          if(defined($Cannonical{$url}{$Hour}{$Var})) {
	      printf ",%s",$Cannonical{$url}{$Hour}{$Var};
	  }
          else { print ",NULL"; }
       }
       print "\n";
    }
}
