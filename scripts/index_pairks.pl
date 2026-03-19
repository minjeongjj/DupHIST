use strict;

my $cat_ks_file = $ARGV[0];
my $pair_file = $ARGV[1];

my (%ks);
open (FH, "$cat_ks_file");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^Sequence/;
	my @info = split /\t/, $line;

	my $pair = $info[0]; 
	my @temp = split /-/, $pair;

	my $gene1 = $temp[0]; 
	my $gene2 = $temp[1];

	my $ks = $info[3];

	if ($ks eq "NA")
	{
		$ks = 0;
	}
	elsif ($ks eq "nan" || $ks eq "-nan")
	{
		$ks = "NAN";
	}

	$ks{$gene1}{$gene2} = $ks;
	$ks{$gene2}{$gene1} = $ks;
}
close FH;

open (FH, "$pair_file");
while (my $line = <FH>)
{
	chomp $line;
	print "$line\tks\n" if $line =~ /^#/;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $gene1 = $info[3];
	my $gene2 = $info[4];

	my $ks = $ks{$gene1}{$gene2};
	$ks = "NAN" if $ks eq "";

	print "$line\t$ks\n";
}
close FH;

