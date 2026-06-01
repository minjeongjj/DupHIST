#!/usr/bin/perl
use strict;
use warnings;

############################################################
# Usage:
#   perl group_nodes_in_nodeinfo.pl nodeinfo.txt > out.txt
#
# For lines where pair_type == "gene-node-multi" and the
# subtree is of the form:
#   (GENE1:len1,GENE2:len2,nodeX:lenX,...)
#
# Behavior:
#   - If exactly 1 gene:
#       (GENE:len,nodeX:len,nodeY:len,...)
#         -> (GENE:len,(nodeX:len,nodeY:len,...))
#
#   - If 2 or more genes:
#       * Group all nodes as plain list: node1,node2,...
#       * Build innermost "(g_short,node1,node2,...)"
#       * Wrap remaining genes (short → long):
#           cluster = (g_i,cluster)
############################################################

my $file = shift or die "Usage: perl $0 <nodeinfo.txt>\n";

open my $IN, "<", $file or die "Cannot open $file: $!\n";

while (<$IN>) {
    chomp;

    # keep comment or empty lines unchanged
    if (/^\s*$/ or /^#/) {
        print "$_\n";
        next;
    }

    my @cols = split /\t/, $_, 4;
    if (@cols < 4) {
        print "$_\n";
        next;
    }

    my ($prefix, $node_id, $pair_type, $subtree) = @cols;

    if ($pair_type eq 'gene-node-multi') {
        my $new = transform_subtree($subtree);
        $subtree = $new if defined $new;
    }

    print join("\t", $prefix, $node_id, $pair_type, $subtree), "\n";
}

close $IN;

############################################################
# transform_subtree
############################################################
sub transform_subtree {
    my ($subtree) = @_;

    # check outer parentheses
    return undef unless $subtree =~ /^\((.*)\)$/;
    my $inside = $1;

    my @tokens = split /,/, $inside;
    return undef if @tokens < 3;  # must be multi-child

    my @gene_idx;
    my @node_idx;
    my %is_node;
    my %bl_gene;  # branch length for genes

    for my $i (0 .. $#tokens) {
        my $tok = $tokens[$i];

        # label and optional branch length
        my ($label, $bl) = $tok =~ /^([^:]+)(?::([0-9.eE+\-]+))?$/;
        return undef unless defined $label;

        my $node_flag = ($label =~ /^node\d+$/) ? 1 : 0;
        $is_node{$i} = $node_flag;

        if ($node_flag) {
            push @node_idx, $i;
        } else {
            push @gene_idx, $i;
            # parse branch length for gene (default 0 if missing)
            my $num = 0;
            if (defined $bl && $bl =~ /^-?(?:\d+\.?\d*|\.\d+)(?:[eE][+\-]?\d+)?$/) {
                $num = $bl;
            }
            $bl_gene{$i} = $num;
        }
    }

    my $gene_count = scalar @gene_idx;
    my $node_count = scalar @node_idx;

    # must have at least one node
    return undef unless $node_count >= 1;

    # ------ Case 1: exactly 1 gene ------
    if ($gene_count == 1) {
        my $gidx     = $gene_idx[0];
        my $gene_tok = $tokens[$gidx];

        my @node_tokens;
        for my $i (0 .. $#tokens) {
            next if $i == $gidx;
            push @node_tokens, $tokens[$i];
        }

        my $nodes_inside = join(",", @node_tokens);
        my $new_subtree  = "(" . $gene_tok . ",(" . $nodes_inside . "))";

        return $new_subtree;
    }

    # ------ Case 2: 2 or more genes ------
    if ($gene_count >= 2) {
        # nodes as plain list (no extra parentheses)
        my @node_tokens;
        for my $i (0 .. $#tokens) {
            next unless $is_node{$i};
            push @node_tokens, $tokens[$i];
        }

        # sort gene indices by branch length ascending
        my @sorted_gene_idx = sort { $bl_gene{$a} <=> $bl_gene{$b} } @gene_idx;

        # base: shortest gene + all nodes
        my $base_idx = shift @sorted_gene_idx;
        my $base_tok = $tokens[$base_idx];

        my $inner = $base_tok;
        if (@node_tokens) {
            $inner .= "," . join(",", @node_tokens);
        }

        my $cluster = "(" . $inner . ")";

        # wrap remaining genes (shorter first, longer last => outermost)
        for my $gi (@sorted_gene_idx) {
            my $gtok = $tokens[$gi];
            $cluster = "(" . $gtok . "," . $cluster . ")";
        }

        return $cluster;
    }

    # if no genes (should not happen), do nothing
    return undef;
}

