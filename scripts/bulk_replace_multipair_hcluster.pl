use strict;
use File::Basename;

my $input_path = $ARGV[0];
my $input_suffix = $ARGV[1];
my $inbwt_path = $ARGV[2];
my $output_path = $ARGV[3];
my $script_path = $ARGV[4];

my @glob = glob ("$input_path/*$input_suffix");

for (my $i=0; $i<@glob; $i++)
{
	(my $prefix_group = basename ($glob[$i])) =~ s/.$input_suffix//g;

	print "perl $script_path/replace_multipair_hcluster.pl $glob[$i] $inbwt_path $prefix_group > $output_path/$prefix_group.nodeinfo_temp\n";
}
