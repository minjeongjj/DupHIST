use strict;
use File::Basename;

my $nwk_path = $ARGV[0];
my $script_path = $ARGV[1];

my @glob = glob ("$nwk_path/*nwk");

for (my $i=0; $i<@glob; $i++)
{
	(my $out_prefix = $glob[$i]) =~ s/\.nwk//;

	print "perl $script_path/index_node.pl $glob[$i] > $out_prefix.nodeinfo\n";
}

