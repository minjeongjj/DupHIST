#!/usr/bin/perl

use strict;
use Statistics::R;
use File::Basename;

# Create a communication bridge with R and start R
my $R = Statistics::R->new();

my $input_matrice = $ARGV[0];
my $output_path = $ARGV[1];
my $ccc_path = $ARGV[2];
my $prefer_order = $ARGV[3];

my @method_type = split /,/, $prefer_order;

my (%method_type);
for (my $i=0; $i<@method_type; $i++)
{
	$method_type{$method_type[$i]} = $i;
}

my @temp_path = split /\//, $input_matrice;
my $prefix = $temp_path[-2];
my $output_file = basename($input_matrice);

system ("mkdir -p $ccc_path/$prefix/");

open (CCC, ">$ccc_path/$prefix/$output_file.ccc");
print CCC "$output_file\t";

my (%ccc);
for (my $j=0; $j<@method_type; $j++)
{
	system ("mkdir -p $output_path/$method_type[$j]/$prefix");

	## run hclust
	$R->set('input_matrice', $input_matrice);
	$R->set('method_type', $method_type[$j]);
	$R->run(q'data = read.table (input_matrice, sep="\t", header=T)');
	$R->run(q'hc = hclust(as.dist(data), method=method_type)');
	
	## save	hclust result for each method
	my $output_file = basename($input_matrice);
	$R->set('b.file', "$output_path/$method_type[$j]/$prefix/$output_file.$method_type[$j].Duplication");
	$R->set('c.file', "$output_path/$method_type[$j]/$prefix/$output_file.$method_type[$j].labels");
	$R->set('d.file', "$output_path/$method_type[$j]/$prefix/$output_file.$method_type[$j].merge");
	$R->run(q'write.table (hc$height, b.file, sep=" ")');
	$R->run(q'write.table (hc$labels, c.file, sep=" ")');
	$R->run(q'write.table (hc$merge, d.file, sep=" ")');
	
	## calculate cophenetic correlation coefficient
	$R->run(q'ccc <- cor(as.dist(data),cophenetic(hc))');
	my $ccc = $R->get('ccc');

	$ccc{$ccc}{$method_type[$j]} ++;

	print CCC "$ccc\t";

	$R->stop();
}

print CCC "\n";
close CCC;

## run hclust for optimal method (optimal method : method that has largest ccc score / when largest ccc score is more than one, select optimal method by preferred order)
foreach my $ccc (sort {$b <=> $a} keys %ccc)
{
	foreach my $method_type (sort {$method_type{$a} <=> $method_type{$b}} keys %{$ccc{$ccc}})
	{
		system ("mkdir -p $output_path/optimal_each/$prefix");

		## run hclust
		$R->set('input_matrice', $input_matrice);
		$R->set('method_type', $method_type);
		$R->run(q'data = read.table (input_matrice, sep="\t", header=T)');
		$R->run(q'hc = hclust(as.dist(data), method=method_type)');
	
		## save	hclust result for each method
		my $output_file = basename($input_matrice);
		$R->set('b.file', "$output_path/optimal_each/$prefix/$output_file.$method_type.Duplication");
		$R->set('c.file', "$output_path/optimal_each/$prefix/$output_file.$method_type.labels");
		$R->set('d.file', "$output_path/optimal_each/$prefix/$output_file.$method_type.merge");
		$R->run(q'write.table (hc$height, b.file, sep=" ")');
		$R->run(q'write.table (hc$labels, c.file, sep=" ")');
		$R->run(q'write.table (hc$merge, d.file, sep=" ")');
	
		last;
	}
	last;
}
