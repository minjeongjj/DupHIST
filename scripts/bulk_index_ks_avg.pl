use strict;
use File::Basename;

my $input_path = $ARGV[0];
my $input_suffix = $ARGV[1];
my $output_path = $ARGV[2];
my $script_path = $ARGV[3];

my @glob = glob ("$input_path/*$input_suffix");

for (my $i=0; $i<@glob; $i++)
{
	(my $out_prefix = $glob[$i]) =~ s/\.$input_suffix$//;
	(my $prefix_group = basename ($glob[$i])) =~ s/.$input_suffix//g;
	
	print "perl $script_path/index_ks_avg.pl $glob[$i] $output_path/$prefix_group.nodeinfo > $output_path/$prefix_group.nodeinfo_ks\n";
}
