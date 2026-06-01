#!/usr/bin/perl
use strict;
use warnings;

############################################################
# Usage:
#   perl validate_gene_count.pl original.nwk revised.nwk
#
# This script:
#   - Reads the first Newick tree from each file
#   - Extracts gene labels (leaf labels)
#   - Excludes labels like nodeX (internal nodes)
#   - Compares gene counts and lists missing/extra genes
############################################################

my ($orig_file, $rev_file) = @ARGV;
die "Usage: perl $0 <original.nwk> <revised.nwk>\n"
    unless defined $orig_file && defined $rev_file;

my $orig_tree = read_first_newick($orig_file);
my $rev_tree  = read_first_newick($rev_file);

my ($orig_count, $orig_genes_href) = extract_genes($orig_tree);
my ($rev_count,  $rev_genes_href)  = extract_genes($rev_tree);

print "Original file: $orig_file\n";
print "Revised  file: $rev_file\n";
print "Original gene count: $orig_count\n";
print "Revised  gene count: $rev_count\n";

if ($orig_count == $rev_count) {
    print "STATUS: OK (same number of genes)\n";
} else {
    print "STATUS: MISMATCH (different number of genes)\n";
}

# Compare gene sets
my %orig_only;
my %rev_only;

for my $g (keys %{$orig_genes_href}) {
    unless (exists $rev_genes_href->{$g}) {
        $orig_only{$g} = 1;
    }
}
for my $g (keys %{$rev_genes_href}) {
    unless (exists $orig_genes_href->{$g}) {
        $rev_only{$g} = 1;
    }
}

if (%orig_only) {
    print "\nGenes present only in ORIGINAL:\n";
    for my $g (sort keys %orig_only) {
        print "  $g\n";
    }
}

if (%rev_only) {
    print "\nGenes present only in REVISED:\n";
    for my $g (sort keys %rev_only) {
        print "  $g\n";
    }
}

############################################################
# read_first_newick(file)
#   Reads up to the first ';' (single tree) and removes
#   whitespace and trailing semicolons.
############################################################
sub read_first_newick {
    my ($file) = @_;
    open my $FH, "<", $file or die "Cannot open $file: $!\n";

    my $tree = "";
    while (<$FH>) {
        chomp;
        $tree .= $_;
        last if /;/;
    }
    close $FH;

    $tree =~ s/\s+//g;
    $tree =~ s/[\d.]+\/[\d.]+//g;
    $tree =~ s/;+$//;

    return $tree;
}

############################################################
# extract_genes(tree_string)
#
# Returns:
#   ($count, \%genes)
#
#   %genes: keys are gene labels (leaf labels)
#
# Rules:
#   - Label is captured as any token before :,),, 
#   - Exclude labels of the form node\d+
#   - Exclude purely numeric labels
############################################################
sub extract_genes {
    my ($tree) = @_;

    my %genes;

    while ($tree =~ /([^\s\(\),:]+)(?=[:,\)])/g) {
        my $label = $1;

        # skip internal node names like node123
        next if $label =~ /^node\d+$/;

        # skip pure numeric labels (likely branch lengths)
        next if $label =~ /^-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?$/;

        $genes{$label} = 1;
    }

    my $count = scalar keys %genes;
    return ($count, \%genes);
}

