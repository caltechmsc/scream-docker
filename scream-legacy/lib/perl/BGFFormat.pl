#!/usr/bin/perl

BEGIN {
    use FindBin qw($Bin);
    use lib $FindBin::Bin;
}

use strict;
use warnings;
use Cwd;
use File::Basename;
use File::Copy;
use File::Path;
use File::Spec;
use Getopt::Long qw(:config no_ignore_case);
use List::Util qw(min max);
use POSIX qw(ceil floor);
use Sys::Hostname;
use Time::Local;
use Data::Dumper;

# Data::Dumper settings
$Data::Dumper::Indent   = 1;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;

if (@ARGV == 0) { help(); }
my ($help, $bgfglob, $debug);

#ABCDEFGHIJKLMNOPQRSTUVWXYZ
#abcdefghijklmnopqrstuvwxyz

#ABCDEFGHIJKLMNOPQRSTUVWXYZ
#abcdefg ijklmnopqrstuvwxyz
GetOptions ('h|help'          => \$help,
	    'b|bgfs=s'        => \$bgfglob,
	    'debug'           => \$debug);

if ($help) { help(); }
if (!$bgfglob) {
    die "BGFFormat :: Must specify BGF(s) with -b\n";
}

############################################################
### Main Routine                                         ###
############################################################

my @bgfs = glob "$bgfglob";
my $nbgfs = @bgfs;
if ($nbgfs == 0) {
    die "BGFFormat :: Could not find any BGFs using: $bgfglob\n";
}

# For each BGF
foreach my $bgf (@bgfs) {
    print "$bgf\n";

    ###
    ### Read BGF
    ###
    open BGF, "$bgf";
    my @lines = <BGF>;
    close BGF;

    # Header
    my $hdr = "";
    while ($lines[0] !~ /^(ATOM|HETATM)/) { $hdr .= shift @lines; }
	
    # Atoms / Residues
    my %atoms    = ();
    my %map      = ();
    my $n        = 0;
    while ($lines[0] !~ /^FORMAT/) {
	my $line = shift @lines;
	my $chn = substr($line,23,1);
	if ($chn eq " ") {
	    die " - ERROR: BGF $bgf is missing chain information!\n";
	}
	my @split = split(/\s+/, $line);

	# $split[1] = Atom number
	$n++;
	$map{$split[1]}   = $n;
	$atoms{$n}{atom}  = $split[0];  # ATOM/HETATM
	$atoms{$n}{anum}  = $n;         # Atom number
	$atoms{$n}{name}  = $split[2];  # Atom name
	$atoms{$n}{res}   = $split[3];  # Residue name
	$atoms{$n}{chain} = $split[4];  # Chain name
	$atoms{$n}{num}   = $split[5];  # Residue number
	$atoms{$n}{x}     = $split[6];  # X
	$atoms{$n}{y}     = $split[7];  # Y
	$atoms{$n}{z}     = $split[8];  # Z
	$atoms{$n}{ff}    = $split[9];  # FF type
	$atoms{$n}{bonds} = $split[10]; # Bonds
	$atoms{$n}{lone}  = $split[11]; # Lone Pair
	$atoms{$n}{chg}   = $split[12]; # Charge
    }
    my $natoms = $n;

    # Connect/Order Header
    my $conhdr = "";
    while ($lines[0] !~ /^(CONECT|ORDER)/) { $conhdr .= shift @lines; }

    # Connect/Order
    while ($lines[0] !~ /^END/) {
	my $line  = shift @lines;
	my @split = split(/\s+/, $line);
	my $type  = shift @split;
	my $a     = shift @split;

	# CONECT
	if ($type eq "CONECT") {
	    foreach (@split) {
		push @{$atoms{$map{$a}}{cnn}}, $map{$_};
	    }
	}

	# ORDER
	if ($type eq "ORDER") {
	    for (my $i = 0; $i < @{$atoms{$map{$a}}{cnn}}; $i++) {
		my $c = $atoms{$map{$a}}{cnn}[$i];
		$atoms{$map{$a}}{ord}{$c} = $split[$i];
	    }
	}
    }

    # Fix conect order
    for (my $n = 1; $n <= $natoms; $n++) {
	# Conect
	if (defined $atoms{$n}{cnn}) {
	    my @cnn = sort {$a <=> $b} @{$atoms{$n}{cnn}};
	    @{$atoms{$n}{conect}} = @cnn;
	}

	# Order
	if (defined $atoms{$n}{ord}) {
	    my @cnn = @{$atoms{$n}{conect}};
	    my @ord = ();
	    foreach my $c (@cnn) {
		push @ord, $atoms{$n}{ord}{$c};
	    }
	    @{$atoms{$n}{order}}  = @ord;
	}
    }

    ###
    ### Print New BGF
    ###
    open OUT, ">$bgf";
    print OUT "$hdr";
    for (my $i = 1; $i <= $natoms; $i++) {
	# Column shift for normal AA hydrogen atoms
	my $aname;
	if (($atoms{$i}{atom} eq "ATOM") &&
	    ($atoms{$i}{name} !~ /^H/)) {
	    $aname = " $atoms{$i}{name}";
	} else {
	    $aname = "$atoms{$i}{name}";
	}

	printf OUT
	    "%-6s %5d %-5s %3s %1s %4d %10.5f%10.5f%10.5f %-5s %2d %1d %8.5f 0   0\n",
	    $atoms{$i}{atom},
	    $i,
	    $aname,
	    $atoms{$i}{res},
	    $atoms{$i}{chain},
	    $atoms{$i}{num},
	    $atoms{$i}{x},
	    $atoms{$i}{y},
	    $atoms{$i}{z},
	    $atoms{$i}{ff},
	    $atoms{$i}{bonds},
	    $atoms{$i}{lone},
	    $atoms{$i}{chg};
    }
    print OUT "$conhdr";
    for (my $i = 1; $i <= $natoms; $i++) {
	# Conect
	if (defined $atoms{$i}{conect}) {
	    my @cnn = @{$atoms{$i}{conect}};
	    printf OUT "%6s%6d", "CONECT", $i;
	    foreach my $c (@cnn) {
		printf OUT "%6d", $c;
	    }
	    print OUT "\n";
	}

	# Order
	if (defined $atoms{$i}{order}) {
	    my @ord = @{$atoms{$i}{order}};
	    printf OUT "%6s%6d", "ORDER", $i;
	    foreach my $o (@ord) {
		printf OUT "%6d", $o;
	    }
	    print OUT "\n";
	}
    }
    print OUT "END\n";

    print "\n";
}


exit;

############################################################
### Help                                                 ###
############################################################

sub help {

    my $help = "
Program:
 :: BGFFormat.pl

Author:
 :: Adam R. Griffith (griffith\@wag.caltech.edu)

Usage:
 :: BGFFormat.pl -b {bgfs}

Input:
 :: -b | --bgfs        :: BGF File(s)
 :: BGF or BGFs to check/fix.
 :: Single BGF: -b prefix.bgf
 :: Multi BGFs: -b '*.bgf'

 :: -h | --help        :: No Input
 :: Displays this help message.

Description:
 :: This program does a *VERY* basic BGF format fix.
 :: It basically checks to make sure that the atom numbers
 :: are sequential starting at 1, and the CONECT records
 :: are also sequential, as in:
 ::   CONECT  1  5  6  7  8
 :: and not:
 ::   CONECT  1  7  8  5  6

";

    die "$help";
}

#0         10        20        30        40        50        60        70        80        90
#0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
#ATOM       1  ZN    ZN B    1   43.67423  37.81411  46.81730 Zn     4 0  2.00000 0   0

