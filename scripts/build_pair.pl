#!/usr/bin/perl
use strict;
#use warnings;

############################################################
# Usage:
#   perl nodeinfo_lr_ks_from_matrix.pl nodeinfo.txt ks_matrix.tsv > out.tsv
#
# nodeinfo.txt:
#   #prefix node_id pair_type newick_subtree
#
# ks_matrix.tsv:
#   header row: gene1  gene2  gene3 ...
#   rows:       numeric matrix, lower triangle has Ks
#
# Output:
#   prefix  node_id pair_type left_gene right_gene Ks
############################################################

my ($nodeinfo_file, $matrix_file) = @ARGV;
die "Usage: perl $0 <nodeinfo.txt> <ks_matrix.tsv>\n"
    unless defined $nodeinfo_file && defined $matrix_file;

############################################################
# 1) Load Ks matrix
############################################################

open my $MFH, "<", $matrix_file; # or die "Cannot open matrix file $matrix_file: $!\n";

my @genes;            # index -> gene_id
my %idx_of;           # gene_id -> index
my @matrix;           # [row][col] numeric

# read header (gene IDs)
while (<$MFH>) {
    next if /^\s*$/;
    chomp;
    my @hdr = split /\s+/, $_;
    @genes = @hdr;
    last;
}

# map gene -> index
for my $i (0 .. $#genes) {
    $idx_of{ $genes[$i] } = $i;
}

# read numeric rows
my $row_idx = 0;
while (<$MFH>) {
    next if /^\s*$/;
    chomp;
    my @vals = split /\s+/, $_;
    $matrix[$row_idx] = \@vals;
    $row_idx++;
}

close $MFH;

############################################################
# 2) Functions for Ks lookup
############################################################

sub get_ks {
    my ($g1, $g2) = @_;

    return "NA" if !defined $g1 || !defined $g2;
    return "NA" if $g1 eq '' || $g2 eq '';

    return "0" if $g1 eq $g2;  # optional self Ks

    return "NA" unless exists $idx_of{$g1} && exists $idx_of{$g2};

    my $i = $idx_of{$g1};
    my $j = $idx_of{$g2};

    my $row = $i > $j ? $i : $j;
    my $col = $i > $j ? $j : $i;

    return "NA" if !defined $matrix[$row] || !defined $matrix[$row][$col];

    my $v = $matrix[$row][$col];
    return $v;
}

############################################################
# 3) Process nodeinfo: build leaf sets and output L-R Ks
############################################################

open my $NFH, "<", $nodeinfo_file or die "Cannot open nodeinfo file $nodeinfo_file: $!\n";

my %leafset;   # node_id => arrayref of leaf genes

print "#prefix\tnode_id\tpair_type\tleft_gene\tright_gene\n";

while (<$NFH>) {
    chomp;
    next if /^\s*$/;
    if (/^#/) {
        # skip header line of nodeinfo
        next;
    }

    
    my @cols = split /\t/, $_, 4;
    unless (@cols == 4) {
        warn "Skipping malformed nodeinfo line: $_\n";
        next;
    }

    my ($prefix, $node_id, $pair_type, $subtree) = @cols;

    $prefix =~ s/Aligned_//g;
    # 3-1) build leafset for this node (bottom-up)
    my $leafs_ref = collect_leaf_genes($subtree, \%leafset);
    $leafset{$node_id} = $leafs_ref;

    # 3-2) only process target pair_types
    unless ($pair_type eq 'gene-gene'
         || $pair_type eq 'gene-node') {
        next;
    }

    # parse top-level children of this subtree
    my ($inside) = $subtree =~ /^\((.*)\)$/;
    unless (defined $inside) {
        warn "Subtree without outer parentheses at $node_id: $subtree\n";
        next;
    }

    my @children = split_top_level($inside);
    if (@children < 2) {
        warn "Less than 2 top-level children at $node_id: $subtree\n";
        next;
    }

    my @left_parts;
    my @right_parts;

    if ($pair_type eq 'gene-gene') {
        # order does not matter: use child1 / child2
        @left_parts  = ($children[0]);
        @right_parts = ($children[1]);
    }
    elsif ($pair_type eq 'gene-node') {
        # ensure LEFT is gene, RIGHT is node (expanded to leaves)
        # we assume exactly 2 children
        my ($c1, $c2) = @children[0,1];

        my ($lab1) = $c1 =~ /^([^\(:]+)(?::[0-9.eE+\-]+)?/;
        my ($lab2) = $c2 =~ /^([^\(:]+)(?::[0-9.eE+\-]+)?/;

        my $is_node1 = defined($lab1) && $lab1 =~ /^node\d+$/ ? 1 : 0;
        my $is_node2 = defined($lab2) && $lab2 =~ /^node\d+$/ ? 1 : 0;

        if (!$is_node1 && $is_node2) {
            # c1 is gene, c2 is node
            @left_parts  = ($c1);
            @right_parts = ($c2);
        }
        elsif ($is_node1 && !$is_node2) {
            # c1 is node, c2 is gene -> swap
            @left_parts  = ($c2);
            @right_parts = ($c1);
        }
        else {
            # both genes or both nodes (unexpected for gene-node)
            # fallback: keep original order
            @left_parts  = ($c1);
            @right_parts = ($c2);
        }
    }

    # 3-3) collect leaf genes under left and right sides
    my $left_genes_ref  = collect_leaf_genes(join(",", @left_parts),  \%leafset);
    my $right_genes_ref = collect_leaf_genes(join(",", @right_parts), \%leafset);

    my @left_genes  = @$left_genes_ref;
    my @right_genes = @$right_genes_ref;

    # 3-4) output all-by-all L-R Ks
    for my $lg (@left_genes) {
        for my $rg (@right_genes) {
            next if $lg eq '' || $rg eq '';
            my $ks = get_ks($lg, $rg);
	    $ks = "NA" if $ks == 100;

	    print join("\t", $prefix, $node_id, $pair_type, $lg, $rg), "\n";
        }
    }
}

close $NFH;

############################################################
# split_top_level($str)
#   Split a comma-separated string into top-level parts,
#   ignoring commas inside parentheses.
#
# Example:
#   "A:0.1,(B:0.2,C:0.3),node4:0.5"
#   -> ["A:0.1", "(B:0.2,C:0.3)", "node4:0.5"]
############################################################
sub split_top_level {
    my ($s) = @_;
    my @parts;
    my $buf = '';
    my $depth = 0;

    for (my $i = 0; $i < length($s); $i++) {
        my $c = substr($s, $i, 1);
        if ($c eq '(') {
            $depth++;
            $buf .= $c;
        }
        elsif ($c eq ')') {
            $depth--;
            $buf .= $c;
        }
        elsif ($c eq ',' && $depth == 0) {
            push @parts, $buf;
            $buf = '';
        }
        else {
            $buf .= $c;
        }
    }
    push @parts, $buf if $buf ne '';

    return @parts;
}

############################################################
# collect_leaf_genes($expr, \%leafset)
#
# Rule (as requested):
#   - Inside any subtree, gene/node names are obtained by:
#       * split by ','  (no depth tracking)
#       * for each token:
#           - remove whitespace
#           - remove '(' and ')'
#           - cut everything after first ':'
#           - result is either a gene ID or node name
#   - If label is numeric, skip (branch length).
#   - If label =~ /^node\d+$/ and exists in %leafset,
#       include all genes from that node.
#   - Else treat label as gene ID.
############################################################
sub collect_leaf_genes {
    my ($expr, $leafset_href) = @_;

    my %genes;

    # remove trailing semicolons if any
    $expr =~ s/;+$/)/ if $expr =~ /\);+$/;

    my @tokens = split /,/, $expr;

    for my $tok (@tokens) {
        $tok =~ s/\s+//g;      # remove whitespace
        $tok =~ s/[()]+//g;    # remove all parentheses

        next if $tok eq '';

        # keep only part before first ':'
        my ($label) = split /:/, $tok, 2;
        next unless defined $label && $label ne '';

        # skip pure numeric tokens (branch lengths)
        if ($label =~ /^-?(?:\d+\.?\d*|\.\d+)(?:[eE][+\-]?\d+)?$/) {
            next;
        }

        if ($label =~ /^node\d+$/) {
            if (exists $leafset_href->{$label}) {
                for my $g (@{ $leafset_href->{$label} }) {
                    $genes{$g} = 1;
                }
            }
        }
        else {
            $genes{$label} = 1;
        }
    }

    my @list = sort keys %genes;
    return \@list;
}

