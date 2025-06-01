use strict;

my $stValue = $ARGV[0];

my @nValue = ();
my %nVal = {};

open(DATA, "$stValue");
my @stData = <DATA>;
chomp(@stData);
close(DATA);

for(my $i=0;$i<@stData; $i++)
{
	my @nInfo = split /[\s\t]+/, $stData[$i];
	my @stID = split /-/,$nInfo[$#nInfo];
 
	$nVal{$nInfo[0]} = $stID[0];
	$nVal{$nInfo[1]} = $stID[1];
}

my @nTotalGene = split /[\t]+/, $stData[$#stData];

#print "$stData[$#stData]\n";

for(my $i=1; $i<=$nTotalGene[1]; $i++)
{
	if($nVal{$i} ne "")
	{
		if($i==$nTotalGene[1])
		{
			print "$nVal{$i}\n";
		}
		else
		{
			print "$nVal{$i}	";
		}
	}
}

##### Print entire Gene pair ID #####

for(my $i=0; $i<@stData; $i++)
{
	my @stInfo = split /[\t]+/, $stData[$i];
	$nValue[$stInfo[0]-1][$stInfo[0]-1] = 0;
	$nValue[$stInfo[1]-1][$stInfo[0]-1] = $stInfo[2];

}

$nValue[$nTotalGene[1]-1][$nTotalGene[1]-1] = 0;


for(my $i=0; $i<$nTotalGene[1]; $i++)
{
	next if ($nVal{$i+1} eq "");

	## next if $ID eq ""

	for(my $j=0; $j<$nTotalGene[1]; $j++)
	{
		next if ($nVal{$j+1} eq "");
		if(($nValue[$i][$j] !~ /[0-9]/)||($nValue[$i][$j] eq ""))
		{
			$nValue[$i][$j] = 100;
		}
		if($j == $nTotalGene[1]-1)
		{
			print "$nValue[$i][$j]";
		}
		else
		{
			print "$nValue[$i][$j]	";
		}
	}
	print "\n";

}
