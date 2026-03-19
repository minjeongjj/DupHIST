use strict;
use File::Basename;

my $pair_file_cat = $ARGV[0];
my $input_path = $ARGV[1];
my $input_suffix = $ARGV[2];

my $divder = "-" x 30;

my ($count1);
open (FH, "$pair_file_cat");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;

	$count1 ++;
}

my @glob = glob ("$input_path/*$input_suffix");

my $count2 = scalar keys @glob;

if ($count1 ne $count2)
{
	print "ERROR total number of ks pair cds file is not match in $input_path/$input_suffix\n";
	print "$divder\n";
}
else
{
	print "entire files have been conducted in $input_path/*$input_suffix\n";
	print "$divder\n";
}

