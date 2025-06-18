#!/usr/bin/perl

use strict;
use Statistics::R;
use File::Basename;

# Create a communication bridge with R and start R
my $R = Statistics::R->new();

my $input_path = $ARGV[0];
my $output_path = $ARGV[1];

my @method_type = ("average","median","acomplete","ward.D","single");

my @input_matrice = glob ("$input_path/*/*matrix");
for (my $i=0; $i<@input_matrice; $i++)
{
	my @temp_path = split /\//, $input_matrice[$i];
	my $prefix = $temp_path[-2];

	for (my $j=0; $j<@method_type; $j++)
	{

		system ("mkdir -p $output_path/$method_type[$j]/$prefix");

		## run hclust
		$R->set('input_matrice', $input_matrice[$i]);
		$R->set('method_type', $method_type[$j]);
		$R->run(q'data = read.table (input_matrice, sep="\t", header=T)');
		$R->run(q'hc = hclust(as.dist(data), method=method_type)');
	
		## save	hclust output file
		my $output_file = basename($input_matrice[$i]);
		$R->set('b.file', "$output_path/$method_type[$j]/$prefix/$output_file.$method_type[$j].Duplication");
		$R->set('c.file', "$output_path/$method_type[$j]/$prefix/$output_file.$method_type[$j].labels");
		$R->set('d.file', "$output_path/$method_type[$j]/$prefix/$output_file.$method_type[$j].merge");
		$R->run(q'write.table (hc$height, b.file, sep=" ")');
		$R->run(q'write.table (hc$labels, c.file, sep=" ")');
		$R->run(q'write.table (hc$merge, d.file, sep=" ")');
	
		$R->stop();
	}
}
