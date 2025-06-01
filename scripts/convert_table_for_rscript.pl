use strict;
use File::Basename;

my $input_ccc = $ARGV[0];
my $output_path = $ARGV[1];

my (@head_index);
open (CCC, "$input_ccc");
my $output_file = basename($input_ccc);
open (OUT, ">$output_path/$output_file.forR");
print OUT "matrix\tccc\tmethod\n";
while (my $stLine = <CCC>)
{
	chomp $stLine;
	if ($stLine =~ /^#/)
	{
		@head_index = split /\t/, $stLine;
	}
	else
	{
		my @stInfo = split /\t/, $stLine;

		my $matrix_name = $stInfo[0];
		for (my $i=1; $i<@stInfo; $i++)
		{
			my $ccc = $stInfo[$i];
			print OUT "$matrix_name\t$ccc\t$head_index[$i]\n";
		}
	}
}
close OUT;
