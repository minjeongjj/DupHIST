use strict;
use File::Basename;

my $nwk_path = $ARGV[0];
my $script_path = $ARGV[1];
my $cds_file = $ARGV[2];
my $output_path = $ARGV[3];

my @glob = glob ("$nwk_path/*nodeinfo");

for (my $i=0; $i<@glob; $i++)
{
	#(my $out_prefix = $glob[$i]) =~ s/\.nwk//;

	print "perl $script_path/extract_multipair_cds.pl $glob[$i] $cds_file $output_path\n";
}

