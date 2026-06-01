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
        print "ERROR file does not exist : $tree_file\n";
        print "$divider\n\n";
        
        close FH;
        close OUT;
        exit 1;
    }

    print OUT "cp $tree_file $temp_nwk_path/$out.nwk\n";
}
close FH;
close OUT;

