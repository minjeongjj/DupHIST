use strict;
use File::Basename;

my $temp_tree_path = $ARGV[0];
my $temp_nwk_path = $ARGV[1];

my @glob = glob ("$temp_tree_path/*treefile");
for (my $i=0; $i<@glob; $i++)
{
	my $file = basename ($glob[$i]);
	(my $out = $file) =~ s/\.treefile//;

	print "cp $glob[$i] $temp_nwk_path/$out.nwk\n";
}

my @glob = glob ("$temp_tree_path/*contree");
for (my $i=0; $i<@glob; $i++)
{
	my $file = basename ($glob[$i]);
	(my $out = $file) =~ s/\.contree//;

	print "cp $glob[$i] $temp_nwk_path/$out.nwk\n";
}

my @glob = glob ("$temp_tree_path/*nwk");
for (my $i=0; $i<@glob; $i++)
{
	my $file = basename ($glob[$i]);
	(my $out = $file) =~ s/\.nwk//;

	print "cp $glob[$i] $temp_nwk_path/$out.nwk\n";
}



