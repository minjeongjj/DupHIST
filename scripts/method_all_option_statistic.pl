#!/usr/bin/perl

use strict;
use Statistics::R;
use File::Basename;

# Create a communication bridge with R and start R
my $R = Statistics::R->new();

my $input_ccc = $ARGV[0];
my $output_path = $ARGV[1];

$R->set('input_ccc', $input_ccc);
$R->run(q'library(agricolae)');
$R->run(q'data = read.table (input_ccc, sep="\t", header=T)');
$R->run(q'result = aov(ccc ~ method, data = data)');
$R->run(q'comparison = LSD.test(result, "method", p.adj="fdr", group=T)');

$R->set('b.file', "$output_path/aov_lsd_test.comparison.result");
$R->run(q'write.table (comparison$groups, b.file, sep=" ")');
