use strict;

my $input_path = $ARGV[0];
my $input_suffix = $ARGV[1];
my $script_path = $ARGV[2];

my @glob = glob ("$input_path/*$input_suffix");

for (my $i=0; $i<@glob; $i++)
{
	#(my $out_prefix = $glob[$i]) =~ s/\.$input_suffix$//;

	print "perl $script_path/hcluster_rscript.pl $glob[$i] $input_path\n";
}
