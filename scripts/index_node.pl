#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

############################################################
# Usage:
#   perl index_node_rawnwk.pl tree.nwk
#
# Output:
#   1) Cleaned Newick string without bootstrap values
#   2) Subtree list in the format:
#        node1    ( ... )
#        node2    ( ... )
#        ...
#   3) Final tree expression:
#        nodeN;
############################################################

my $file = shift or die "Usage: perl $0 <tree.nwk>\n";

############################################################
# 1) Read Newick
############################################################
open my $FH, '<', $file or die "Cannot open $file: $!\n";
my $tree = '';
while (<$FH>) {
    chomp;
    $tree .= $_;
    last if /;/;   # read only the first tree
}
close $FH;

# remove whitespaces
$tree =~ s/\s+//g;
$tree =~ s/[\d.]+\/[\d.]+//g;

# temporarily remove trailing semicolons and remember if they existed
my $has_semicolon = ($tree =~ s/;+$//) ? 1 : 0;

############################################################
# 2) Remove bootstrap values
#    Pattern examples:
#      )100:0.123
#      )0.95:0.083
############################################################

# Case 1: )<number>:branch_length  →  ):
$tree =~ s/\)([0-9.eE+-]+):/):/g;

# Case 2: )<number><,|)|[>  →  )<,|)|[>
$tree =~ s/\)([0-9.eE+-]+)([,)\[])/)$2/g;

my $clean = $tree;
$clean .= ';' if $has_semicolon;

############################################################
# 3) Extract subtrees (bottom-up labeling by parentheses)
############################################################

my $work = $tree;   # use string without semicolon
my $idx  = 0;
my @records;

# Replace innermost "( ... )" with node1, node2, ...
while ($work =~ /\(([^()]+)\)/) {
    my $inside = $1;   # content inside parentheses
    my $full   = $&;   # full match "( ... )"

    $idx++;
    my $name = "node$idx";

    push @records, {
        name   => $name,
        inside => $inside,
    };

    # Replace this subtree with nodeX only once
    $work =~ s/\Q$full\E/$name/;
}

(my $prefix = (basename ($file))) =~ s/\..*//g;

# Print subtree list
print "#prefix\tnode_id\tpair_type\tnewick_subtree\n";
for my $r (@records) {
    my $inside  = $r->{inside};       # inside of parentheses
    my $subtree = '(' . $inside . ')';

    # split direct children by comma
    my @parts = split /,/, $inside;

    # remove branch lengths and spaces
    for my $p (@parts) {
	#$p =~ s/[\d.]+\/[\d.]+$//g;
        $p =~ s/:[0-9.eE+-]+$//;   # strip trailing branch length
	$p =~ s/\s+//g;
    }

    my $nchild = scalar @parts;

    # classify each child as node or gene
    my @is_node = map { /^node\d+$/ ? 1 : 0 } @parts;

    my $pair_type;

    if ($nchild == 2) {
        # binary subtree
        if ($is_node[0] && $is_node[1]) {
            $pair_type = 'node-node';
        }
        elsif (!$is_node[0] && !$is_node[1]) {
            $pair_type = 'gene-gene';
        }
        else {
            $pair_type = 'gene-node';
        }
    }
    else {
        # multi-child subtree (>=3)
        my $node_count = 0;
        $node_count += $_ for @is_node; 

        if ($node_count == $nchild) {
            # all children are nodes
            $pair_type = 'node-node-multi';
        }
        elsif ($node_count == 0) {
            # all children are genes
            $pair_type = 'gene-gene-multi';
        }
        else {
            # mixture of nodes and genes
            $pair_type = 'gene-node-multi';
        }
    }

    print $prefix, "\t", $r->{name}, "\t", $pair_type, "\t", $subtree, "\n";
}

