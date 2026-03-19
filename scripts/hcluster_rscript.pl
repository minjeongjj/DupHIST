#!/usr/bin/perl

use strict;
use Statistics::R;
use File::Basename;

# Create a communication bridge with R and start R
my $R = Statistics::R->new();

my $input_matrice = $ARGV[0];
my $output_path = $ARGV[1];

## run hclust
$R->set('input_matrice', $input_matrice);
$R->set('method_type', 'median');
$R->run(q'data = read.table (input_matrice, sep="\t", header=T)');
$R->run(q'hc = hclust(as.dist(data), method=method_type)');

## save nwk tree
(my $output_file = basename($input_matrice)) =~ s/\.matrix//;

#$R->run(q'if (!requireNamespace("ape", quietly=TRUE)) install.packages("ape", repos="http://cran.us.r-project.org")');
$R->run(q'library(ape)');
$R->set('nwk_file', "$output_path/$output_file.nwk");
$R->run(q'tree <- as.phylo(hc)');
$R->run(q'write.tree(tree, file=nwk_file)');
	
$R->stop();

