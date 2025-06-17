use strict;

my $path = $ARGV[0];
my @stDuplication = glob("$path/*/*.Duplication");
my @stMerge = glob("$path/*/*.merge");
my @stLabel = glob("$path/*/*.labels");

for(my $i=0; $i<@stDuplication; $i++)
{
	my %stLabel;
	my %stList;
	open(DATA, "$stLabel[$i]");
	while(my $stLine = <DATA>)
	{
		chomp($stLine);
		$stLine =~ s/\"//g;
		my @stInfo = split / /, $stLine;
		$stList{$stInfo[0]} = $stInfo[1];
	}
	close(DATA);
	open(DATA, "$stMerge[$i]");
	while(my $stLine = <DATA>)
	{
		chomp($stLine);
		my @stInfo = split / /, $stLine;
		for(my $j=1;$j<3;$j++)
		{
			if($stInfo[$j] <0)
			{
				$stInfo[$j] = $stInfo[$j]*-1;
				$stLabel{$stInfo[0]}{$j} = $stList{$stInfo[$j]};
			}
			else
			{
				$stLabel{$stInfo[0]}{$j} = "G$stInfo[$j]";
			}
		}
#		$stTemp{$stInfo[0]} = "$stLabel{$stInfo[0]}{1},$stLabel{$stInfo[0]}{2}";
	}
	close(DATA);
	open(DATA, "$stDuplication[$i]");
	open(OUT, ">$stDuplication[$i].merged");
	while(my $stLine = <DATA>)
	{
		chomp($stLine);
		my @stInfo = split / /, $stLine;
		next if ($stInfo[1] eq "");
		print OUT "$stInfo[0]	$stInfo[1]	$stLabel{$stInfo[0]}{1},$stLabel{$stInfo[0]}{2}\n";
	}
	close(DATA);
	close(OUT);

	

}
