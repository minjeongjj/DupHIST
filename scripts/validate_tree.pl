use strict;

my $group_info = $ARGV[0];
my $file_path = $ARGV[1];

my (%groupinfo, %total);
open (FH, "$group_info");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $prefix = $info[0];
	my $group = $info[1];
	my $geneid = $info[2];

	my $prefix_group = "$prefix\_$group";

	$groupinfo{$prefix_group}{$geneid} ++;
	$total{$prefix_group}{$geneid} ++;
}
close FH;

my (%tree);
my @glob = glob ("$file_path/*pairks");
for (my $i=0; $i<@glob; $i++)
{
	open (FH, "$glob[$i]");
	while (my $line = <FH>)
	{
		chomp $line;
		next if $line =~ /^#/;
		my @info = split /\t/, $line;

		my $prefix_group = $info[0];
		my $gene1 = $info[3];
		my $gene2 = $info[4];

		$tree{$prefix_group}{$gene1} ++;
		$tree{$prefix_group}{$gene2} ++;

		$total{$prefix_group}{$gene1} ++;
		$total{$prefix_group}{$gene2} ++;
	}
	close FH;
}

my $divider = "-" x 30;
my $cnt = "";
foreach my $prefix_group (sort {$a cmp $b} keys %total)
{
	foreach my $geneid (sort {$a cmp $b} keys %{$total{$prefix_group}})
	{
		if ($groupinfo{$prefix_group}{$geneid} eq "" || $tree{$prefix_group}{$geneid} eq "")
		{
			$cnt ++;
			print "[ERROR] Invalid gene IDs or unpruned internodes detected in the custom tree. The tree MUST contain matching gene IDs only. Please remove all invalid nodes or update the group info to proceed.\n" if $cnt == 1;
			print "$divider\n" if $cnt == 1;
			print "$geneid\n";
		}
	}
}
