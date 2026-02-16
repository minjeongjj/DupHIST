use strict;
use File::Basename;

my $algorithm_file = $ARGV[0];
my $msa_path = $ARGV[1];
my $out_dir = $ARGV[2];

my $current_path = dirname ($algorithm_file);

open (FH, "$algorithm_file");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $prefix_group = $info[0];
	my $ml_method = $info[3];

	if ($ml_method eq "fasttree")
	{
		print "fasttree -wag -gamma $msa_path/$prefix_group.mafft > $out_dir/$prefix_group.nwk\n";
	}
	elsif ($ml_method eq "iqtree_boot")
	{
		print "iqtree -s $msa_path/$prefix_group.mafft -alrt 1000 -B 1000 -T 1 -safe -pre $out_dir/$prefix_group\n";
	}
	elsif ($ml_method eq "iqtree_noboot")
	{
		print "iqtree -s $msa_path/$prefix_group.mafft -T 1 -safe -pre $out_dir/$prefix_group\n";
	}
}
close FH;
