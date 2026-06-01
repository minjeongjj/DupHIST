#!/usr/bin/perl
use strict;
use warnings;

############################################################
# Usage:
#   perl nodeinfo_to_newick.pl PLUN_OG0001939.nodeinfo > PLUN_OG0001939.nwk
#
# Input format (tab-separated):
#   #prefix  node_id pair_type   newick_subtree
#   PLUN_OG0001939  node1   gene-gene   (A:0.1,B:0.2)
#   PLUN_OG0001939  node2   gene-node   (C:0.3,node1:0.4)
#   ...
#
# Assumptions:
#   - Lines are in topological order: node1 defined before
#     any node that uses node1 inside its subtree.
#   - Last non-header line corresponds to the root node.
#
# Behavior:
#   - For each line, expand occurrences of "nodeX" in the
#     subtree using previously stored subtrees for nodeX.
#   - Attach branch length if present: nodeX:0.01 becomes
#     (SUBTREE_FOR_nodeX):0.01
#   - At the end, print the fully expanded subtree of the
#     last node as a Newick tree followed by ";".
############################################################

my $file = shift or die "Usage: perl $0 <nodeinfo.txt>\n";

open my $IN, "<", $file or die "Cannot open $file: $!\n";

my %subtree_of;      # node_id => expanded subtree string "(...)"
my $last_node_id;
my $last_prefix;

while (<$IN>) {
    chomp;
    next if /^\s*$/;     # skip empty lines
    next if /^#/;        # skip header/comment line

    my @cols = split /\t/, $_, 4;
    unless (@cols == 4) {
        warn "Skipping malformed line: $_\n";
        next;
    }

    my ($prefix, $node_id, $pair_type, $subtree) = @cols;

    # remove trailing semicolon if any
    $subtree =~ s/;+$/)/ if $subtree =~ /\);+$/;

    # expand any nodeX or nodeX:bl inside the subtree
    # using already defined %subtree_of
    # pattern: nodeXX optionally followed by :branch_length
    $subtree =~ s/\b(node\d+)(:[0-9.eE+\-]+)?/
        expand_node($1, $2, \%subtree_of)
/eg;

    # store expanded subtree for this node
    $subtree_of{$node_id} = $subtree;

    # remember last node (root)
    $last_node_id = $node_id;
    $last_prefix  = $prefix;
}

close $IN;

if (defined $last_node_id && exists $subtree_of{$last_node_id}) {
    my $final_tree = $subtree_of{$last_node_id};

    # ensure it is wrapped in parentheses at top-level
    # if not already
    unless ($final_tree =~ /^\(.*\)$/) {
        $final_tree = "(" . $final_tree . ")";
    }

    print $final_tree, ";\n";
} else {
    die "No valid nodes found in input.\n";
}

############################################################
# expand_node(node_id, branch_len, subtree_hashref)
#
# If node_id exists in %subtree_of:
#   nodeX:bl  -> (SUBTREE_FOR_nodeX):bl
#   nodeX     -> (SUBTREE_FOR_nodeX)
#
# If not defined yet, leave it as is.
############################################################
sub expand_node {
    my ($nid, $bl, $href) = @_;

    if (exists $href->{$nid}) {
        my $sub = $href->{$nid};    # e.g. "(A:0.1,B:0.2)"
        # wrap in parentheses in case it is not
        $sub = "(" . $sub . ")" unless $sub =~ /^\(.*\)$/;
        $bl  = "" unless defined $bl;
        return $sub . $bl;
    } else {
        # unknown node id, return as original text
        $bl = "" unless defined $bl;
        return $nid . $bl;
    }
}

