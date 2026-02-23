use strict;

my $group_file = $ARGV[0];
my $pep_file = $ARGV[1];
my $size_threshold = $ARGV[2];
my $out_dir = $ARGV[3];

my (%pep, $gene_id);
open (FH, "$pep_file");
while (my $line = <FH>)
{
	chomp $line;
	if ($line =~ />([^\s\t]+)/)
	{
		$gene_id = $1;
	}
	else
	{
		$pep{$gene_id} .= uc $line;
	}
}
close FH;

my (%data);
open (FH, "$group_file");
while (my $line = <FH>)
{
	chomp $line;
	my @info = split /\t/, $line;

	my $prefix = $info[0];
	my $group = $info[1];
	my $geneid = $info[2];

	my $data = "$prefix\_$group";
	$data{$data}{$geneid} ++;
}
close FH;

my (%count, %noredun);
foreach my $data (sort {$a cmp $b} keys %data)
{
	open (OUT, ">$out_dir/$data.pep.fa");
	foreach my $gene_id (sort {$a cmp $b} keys %{$data{$data}})
	{
		print OUT ">$gene_id\n$pep{$gene_id}\n";

		$noredun{$data}{$pep{$gene_id}} ++;
		$count{$data}{$gene_id} ++;
	}
	close OUT;
}

open (OUT, ">$out_dir/../hybrid_algorithm.info");
print OUT "#index\tcnt\tredun_del\tml\n";
foreach my $data (sort {$a cmp $b} keys %count)
{
	my $ncnt = scalar keys %{$count{$data}};
	my $noredun = scalar keys %{$noredun{$data}};

	my $ml = "";
	if ($ncnt > $size_threshold)
	{
		$ml = "fasttree";
	}
	else
	{
		$ml = "iqtree_boot";

		if ($noredun <= 3)
		{
			$ml = "iqtree_noboot";
		}

		if ($ncnt == 2)
		{
			$ml = "fasttree";
		}
	}

	print OUT "$data\t$ncnt\t$noredun\t$ml\n";
}
close OUT;
