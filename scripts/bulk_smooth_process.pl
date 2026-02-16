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
	
	print "perl $script_path/validate_ks_pairks.pl $input_path/$prefix_group.geneks_1st $input_path/$prefix_group.pairks > $input_path/$prefix_group.geneks_1st_val\n";
	
	print "perl $script_path/smooth_parent_inv.pl $input_path/$prefix_group.geneks_1st $input_path/$prefix_group.pairks > $input_path/$prefix_group.geneks_2nd\n";
	print "perl $script_path/validate_ks_pairks.pl $input_path/$prefix_group.geneks_2nd $input_path/$prefix_group.pairks > $input_path/$prefix_group.geneks_2nd_val\n";

	print "perl $script_path/smooth_lastleaf_inv.pl $input_path/$prefix_group.geneks_2nd $input_path/$prefix_group.geneks_2nd_val $input_path/$prefix_group.pairks $input_path/$prefix_group.nodeinfo_ks > $input_path/$prefix_group.geneks_3rd\n";
	print "perl $script_path/validate_ks_pairks.pl $input_path/$prefix_group.geneks_3rd $input_path/$prefix_group.pairks > $input_path/$prefix_group.geneks_3rd_val\n";

	print "perl $script_path/smooth_inbetween_inv.pl $input_path/$prefix_group.geneks_3rd $input_path/$prefix_group.geneks_3rd_val $input_path/$prefix_group.pairks $input_path/$prefix_group.nodeinfo_ks $input_path/$prefix_group.geneks_4th\n";
	print "perl $script_path/validate_ks_pairks.pl $input_path/$prefix_group.geneks_4th $input_path/$prefix_group.pairks > $input_path/$prefix_group.geneks_4th_val\n";
}
