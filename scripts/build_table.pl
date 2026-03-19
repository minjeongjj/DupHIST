use strict;

my $gene_ks = $ARGV[0];
my $node_info = $ARGV[1];

my (%ks);
open (FH, "$gene_ks");
while (my $line = <FH>)
{
	chomp $line;
	my @info = split /\t/, $line;

	my $prefix = $info[0];
	my $group = $info[1];
	my $gene_id = $info[2];

	my $ks = $info[-1];

	$ks{$gene_id} = $ks;
}
close FH;

open (FH, "$node_info");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $prefix_group = $info[0];
	my $node_name = $info[1]; 
	my $index = $info[2];
	(my $subtree = $info[3]) =~ s /\(|\)//g;

	next if $index =~ /node-node-multi/;

	my @temp = split /,/, $subtree;

	(my $data1 = $temp[0]) =~ s/\:.*|\(|\)//g;
	(my $data2 = $temp[1]) =~ s/\:.*|\(|\)//g;

	my @temp = split /_/, $prefix_group;
	my $prefix = $temp[0];
	my $group = $temp[1];

	my $ks = "";
	$ks = $ks{$data1} if $ks{$data1} ne "";
	$ks = $ks{$data2} if $ks{$data2} ne "";

	my @temp = sort {$a cmp $b} ($data1, $data2);
	my $data1 = $temp[0];
	my $data2 = $temp[1];

	$ks = "-" if $ks eq "";
	$ks = sprintf ("%.5f", $ks);

	print "$prefix\t$group\t$node_name\t$data1\t$data2\t$ks\n";
}
close FH;
