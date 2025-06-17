use strict;

my $stDir = $ARGV[0];

my @stMatrix = glob("$stDir/*.CDS.fasta");
#my @stMatrix = glob("$stDir/*.Average");
#my @stMatrix = glob("$stDir/*.Median");
#my @stMatrix = glob("$stDir/*.merged");


my $Cnt_Matrix = 0;

for(my $i=0; $i<@stMatrix; $i++)
{
	$Cnt_Matrix ++;
}

print "$Cnt_Matrix\n";
