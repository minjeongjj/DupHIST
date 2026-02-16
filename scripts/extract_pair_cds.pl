use strict;

my $pair_file = $ARGV[0];
my $cds_file = $ARGV[1];
my $output_path = $ARGV[2];

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
		$cds{$gene_id} = uc $line;
	}
}
close FH;

my ($count);
open (FH, "$pair_file");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $prefix_group = $info[0];
	my $node_name = $info[1];

	my $gene1 = $info[3];
	my $gene2 = $info[4];

	$count ++;

	open (OUT, ">$output_path/$prefix_group.$node_name.$count.cds.fa");
	print OUT ">$gene1\n$cds{$gene1}\n>$gene2\n$cds{$gene2}\n";
	close OUT;
}
close FH;
