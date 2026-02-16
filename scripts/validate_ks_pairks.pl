use strict;

my $gene_ks = $ARGV[0];
my $pair_file = $ARGV[1];

my (%ks);
open (FH, "$gene_ks");
while (my $line = <FH>)
{
	chomp $line;
	my @info = split /\t/, $line;

	my $gene_id = $info[2];
	my $ks = $info[-1];

	$ks{$gene_id} = $ks;
}
close FH;

open (FH, "$pair_file");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $gene1 = $info[3];
	my $gene2 = $info[4];

	my $ks1 = $ks{$gene1};
	my $ks2 = $ks{$gene2};

	next if $ks1 eq "NA" || $ks2 eq "NA";

	if ($ks1 < $ks2)
	{
		print "$info[0]\t$gene1\t$gene2\t$ks1\t$ks2\n";
	}
}
close FH;
