use strict;

my $node_info = $ARGV[0];
my $cds_file = $ARGV[1];
my $output_path = $ARGV[2];

my (%data, %select, %line);
open (FH, "$node_info");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $prefix_group = $info[0];
	my $node_name = $info[1];
	my $index = $info[2];
	(my $subtree = $info[3]) =~ s/\(|\)//g;

	next if $index ne "gene-gene-multi";

	$line{$prefix_group}{$line} ++;

	my @temp = split /,/, $subtree;
	for (my $i=0; $i<@temp; $i++)
	{
		(my $gene_id = $temp[$i]) =~ s /\:.*//g;

		$data{$prefix_group}{$node_name}{$gene_id} ++;
		$select{$gene_id} ++;
	}
}
close FH;

my ($gene_id, %cds);
open (FH, "$cds_file");
while (my $line = <FH>)
{
	chomp $line;
	if ($line =~ />([^\s\t]+)/)
	{
		$gene_id = $1;
	}
	else
	{
		next if $select{$gene_id} eq "";

		$cds{$gene_id} .= uc $line;
	}
}
close FH;

foreach my $prefix_group (sort {$a cmp $b} keys %data)
{
	open (OUT, ">$output_path/$prefix_group.multi");
	foreach my $line (sort {$a cmp $b} keys %{$line{$prefix_group}})
	{
		print OUT "$line\n";
	}
	close OUT;

	foreach my $node_name (sort {$a cmp $b} keys %{$data{$prefix_group}})
	{
		open (OUT, ">$output_path/$prefix_group.$node_name.combi");

		my ($cnt1);
		foreach my $gene1 (sort {$a cmp $b} keys %{$data{$prefix_group}{$node_name}})
		{
			$cnt1 ++;

			my ($cnt2);
			foreach my $gene2 (sort {$a cmp $b} keys %{$data{$prefix_group}{$node_name}})
			{
				$cnt2 ++;
				next if $gene1 eq $gene2;
				next if $cnt1 >= $cnt2;

				print OUT "$prefix_group\t$node_name\t$gene1\t$gene2\t$cnt1\t$cnt2\n";
			}
		}
	}
	close OUT;
}

foreach my $prefix_group (sort {$a cmp $b} keys %data)
{
	foreach my $node_name (sort {$a cmp $b} keys %{$data{$prefix_group}})
	{
		my ($cnt1);
		foreach my $gene1 (sort {$a cmp $b} keys %{$data{$prefix_group}{$node_name}})
		{
			$cnt1 ++;

			my ($cnt2);
			foreach my $gene2 (sort {$a cmp $b} keys %{$data{$prefix_group}{$node_name}})
			{
				$cnt2 ++;
				next if $gene1 eq $gene2;
				next if $cnt1 >= $cnt2;

				open (OUT, ">$output_path/$prefix_group.$node_name.$cnt1.$cnt2.cds.fa");
				print OUT ">$gene1\n$cds{$gene1}\n>$gene2\n$cds{$gene2}\n";
				close OUT;
			}
		}
	}
}
