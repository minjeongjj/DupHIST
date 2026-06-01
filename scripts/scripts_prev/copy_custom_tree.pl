use strict;
use File::Basename;

my $custom_tree_list = $ARGV[0];
my $temp_nwk_path    = $ARGV[1];
my $temp_sh          = $ARGV[2];
my $divider          = "=" x 30;

open (FH, $custom_tree_list) or die "Cannot open $custom_tree_list: $!";
open (OUT, ">$temp_sh/total_custom_copy.sh");

while (my $line = <FH>)
{
    chomp $line;
    next if $line =~ /^#/ or $line eq "";
    
    my @info = split /\t/, $line;

    my $prefix    = $info[0];
    my $group     = $info[1];
    my $tree_file = $info[2];

    my $out = "${prefix}_${group}";

    if (! -e $tree_file || -s $tree_file == 0)
    {
        print "\n$divider\n";
        print "[FILE NOT FOUND OR EMPTY] Invalid custom tree file for Group: $group\n";
        print "'duphist' requires a valid precomputed Newick tree file to bypass the tree-building step.\n";
        print "The specified path is either missing, corrupted, or has a file size of 0 KB.\n";
        print "  - Target Group : $group (Prefix: $prefix)\n";
        print "  - Resolved Path: $tree_file\n";
        print "Please verify your input list file and ensure the tree path is correct.\n";
        print "$divider\n\n";
        
        close FH;
        close OUT;
        exit 1;
    }

    print OUT "cp $tree_file $temp_nwk_path/$out.nwk\n";
}
close FH;
close OUT;

