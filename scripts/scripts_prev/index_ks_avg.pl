use strict;

my $pair_ks = $ARGV[0];
my $node_info = $ARGV[1];

my (%count, %add);
open (FH, "$pair_ks");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $node_name = $info[1];
	my $ks = $info[5];

	next if $ks eq "NAN";

	$count{$node_name} ++;
	$add{$node_name} += $ks;
}
close FH;

my (%avg);
foreach my $node_name (sort {$a cmp $b} keys %count)
{
	my $cnt = $count{$node_name};
	my $total = $add{$node_name};
	my $avg = sprintf ("%.5f", ($total / $cnt));

	$avg{$node_name} = $avg;
}

open (Info, "$node_info");
while (my $line = <Info>)
{
	chomp $line;
	print "$line\tks_avg\n" if $line =~ /^#/;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $node_name = $info[1];
	my $pair_type = $info[2];
	my $ks_avg = $avg{$node_name};

	if ($pair_type eq "gene-gene-multi")
	{
		$ks_avg = 0;
	}
	elsif ($pair_type eq "node-node" || $pair_type eq "node-node-multi")
	{
		$ks_avg = $pair_type;
	}

	$ks_avg = "NAN" if $ks_avg eq "";	
	print "$line\t$ks_avg\n";
}
close Info;
