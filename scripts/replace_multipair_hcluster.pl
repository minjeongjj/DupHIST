use strict;
use File::Basename;

my $node_info = $ARGV[0];
my $hcluster_path = $ARGV[1];
my $target_prefix = $ARGV[2];

my (%data, %max);
my @glob = glob ("$hcluster_path/*$target_prefix*nwk");
for (my $i=0; $i<@glob; $i++)
{
	my $file = basename ($glob[$i]);
	my @temp = split /\./, $file;

	my $node_name = $temp[1];

	my $max_branch = "";
	open (FH, "$glob[$i]");
	while (my $line = <FH>)
	{
		chomp $line;

		(my $tree = $line) =~ s/;$//;

		my @temp = split /:|,|\(|\)/, $tree;
		for (my $j=0; $j<@temp; $j++)
		{
			(my $branch_len = $temp[$j]) =~ s/\)|\(|,|\s|\t//g;

			if ($branch_len =~ /^-?(?:\d+\.?\d*|\.\d+)$/)
			{
				$max_branch = $branch_len if $max_branch eq "" || $max_branch < $branch_len;
			}
		}

		$data{$node_name} = $tree;
		$max{$node_name} = $max_branch;
	}
	close FH;
}

open (Info, "$node_info");
while (my $line = <Info>)
{
	chomp $line;
	print "$line\n" if $line =~ /^#/;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $node_name = $info[1];
	my $pair_type = $info[2];
	my $subtree = $info[3];

	#print "$line\t$data{$node_name}\t$max{$node_name}\n";

	if ($pair_type eq "gene-gene-multi" && $data{$node_name} ne "" && $max{$node_name} > 0)
	{
		$subtree = $data{$node_name};
		$pair_type = "gene-gene-multi-replace";
	}

	if ($pair_type eq "gene-gene-multi")
	{
		$subtree = $data{$node_name};
		$pair_type = "gene-gene-multi-replace";
		#$pair_type = "gene-gene-multi-sameks";
	}

	$info[0] =~ s/_fasttree2//g;
	$info[2] = $pair_type;
	$info[3] = $subtree;
	$line = join ("\t", @info);

	print "$line\n";
}
close Info;

