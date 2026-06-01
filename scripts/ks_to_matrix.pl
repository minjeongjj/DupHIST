use strict;

my $combi_file = $ARGV[0];
my $pair_path = $ARGV[1];

(my $kaks_prefix = $combi_file) =~ s/\.combi//g;

my (%ks);
my @glob = glob ("$kaks_prefix*kaks");
for (my $i=0; $i<@glob; $i++)
{
	open (FH, "$glob[$i]");
	while (my $line = <FH>)
	{
		chomp $line;
		next if $line =~ /^Sequence/;
		my @info = split /\t/, $line;

		my $gene_pair = $info[0];
		my $ks = $info[3];

		my @temp = split /-/, $gene_pair;
		my $gene1 = $temp[0];
		my $gene2 = $temp[1];

		$ks{$gene1}{$gene2} = $ks;
		$ks{$gene2}{$gene1} = $ks;
	}
}

my $line = "";
foreach my $gene1 (sort {$a cmp $b} keys %ks)
{
	$line .= "$gene1\t";
}
$line =~ s/\t$//;
print "$line\n";

foreach my $gene1 (sort {$a cmp $b} keys %ks)
{
	my $line = "";
	foreach my $gene2 (sort {$a cmp $b} keys %ks)
	{
		my $ks = "";
		if ($gene1 eq $gene2)
		{
			$ks = "0";
		}
		else
		{
			$ks = $ks{$gene1}{$gene2};
		}

		if ($ks eq "NA")
		{	
			$ks = 0;
		}
		elsif ($ks eq "nan" || $ks eq "-nan")
		{
			$ks = 100;
		}

		$line .= "$ks\t";
	}
	$line =~ s/\t$//;

	print "$line\n";
}
