use strict;

my $pair_path = $ARGV[0];
my $pair_suffix = $ARGV[1];
my $script_path = $ARGV[2];

my @glob = glob ("$pair_path/*$pair_suffix");

for (my $i=0; $i<@glob; $i++)
{
	(my $out_prefix = $glob[$i]) =~ s/\.$pair_suffix$//;

	print "perl $script_path/ks_to_matrix.pl $glob[$i] > $out_prefix.matrix\n";
}
