use strict;

my $stMethod = $ARGV[0];
my $path = $ARGV[1];
my @stMerge = glob("$path/*/*.matrix.*.Duplication.merged");

for(my $i=0; $i<@stMerge; $i++)
{
	my $stOut = $stMerge[$i];
	$stOut =~ s/matrix.*.Duplication.merged/result.$stMethod/g;
	my (%fKA,%fKS,%fKAKS,%nGroup,%stTemp) = {};
	my $stKAKS = $stMerge[$i];
	$stKAKS =~ s/matrix.*.Duplication.merged//g;
	$stKAKS = $stKAKS."Kaks";
	open(DATA, "$stKAKS");
	while(my $stLine = <DATA>)
	{
		chomp($stLine);
		my @stInfo = split /[\t]+/, $stLine;
		$stInfo[0] =~ s/\|/./g;
		my @stID = split /[-]/, $stInfo[0];
		$fKA{"$stID[0],$stID[1]"} = $stInfo[2];
		$fKA{"$stID[1],$stID[0]"} = $stInfo[2];
		$fKS{"$stID[0],$stID[1]"} = $stInfo[3];
		$fKS{"$stID[1],$stID[0]"} = $stInfo[3];
		$fKAKS{"$stID[0],$stID[1]"} = $stInfo[4];
		$fKAKS{"$stID[1],$stID[0]"} = $stInfo[4];

	}
	close(DATA);

	#print "$stOut\n";
	%nGroup = {};
	open(DATA, "$stMerge[$i]");
	while(my $stLine = <DATA>)
	{
		chomp($stLine);
		my @stInfo = split /[\t]+/, $stLine;
		$stInfo[0] =~ s/\"//g;
		$stInfo[0] = "G$stInfo[0]";
		my @stTemp = split /,/, $stInfo[2];
	
		if (($stTemp[0] !~ /^G[0-9]+/)&&($stTemp[1] !~ /^G[0-9]+/))
		{
			$nGroup{$stInfo[0]} = $stInfo[2];
		}
		else
		{
			if (($stTemp[0] =~ /^G[0-9]+/)&&($stTemp[1] =~ /^G[0-9]+/))
			{
				$nGroup{$stInfo[0]} =  $nGroup{$stTemp[0]}.",$nGroup{$stTemp[1]}";
			}
			elsif($stTemp[0] =~ /^G[0-9]+/)
			{
				$nGroup{$stInfo[0]} = $nGroup{$stTemp[0]}.",$stTemp[1]";
			}
			elsif($stTemp[1] =~ /^G[0-9]+/)
			{
				$nGroup{$stInfo[0]} = $nGroup{$stTemp[1]}.",$stTemp[0]";
			}
		}

	}
	close(DATA);

	close(DATA);
	open(DATA, "$stMerge[$i]");
	open(OUT, ">$stOut");
	while(my $stLine = <DATA>)
	{
		chomp($stLine);
		my @stInfo = split /[\t]+/, $stLine;
		$stInfo[0] =~ s/\"//g;
		$stInfo[0] = "G$stInfo[0]";

		my @stID = split /,/, $stInfo[2];
		my ($fKA,$fKS,$fKAKS) = &CalcKAKS(\@stID,\%nGroup,\%fKA,\%fKS,\%fKAKS,$stInfo[0]);
		if($fKAKS>10)
		{
			$fKAKS = 10;
		}

		$stLine = "$stInfo[0]	$stInfo[1]	$fKS	$fKA	$fKAKS	$stInfo[2]";
		print OUT "$stLine\n";
	}
	close(DATA);
	close(OUT);

}

sub CalcKAKS
{
	my @stID = @{$_[0]};
	my %nGroup = %{$_[1]};
	my %fKA = %{$_[2]};
	my %fKS = %{$_[3]};
	my %fKAKS = %{$_[4]};
	my $nGroup = $_[5];

	my ($fKAKS,$fKA,$fKS);
	my @fKAKS;
	my @fKA;
	my @fKS;

	my @stTempID;
	my %stTemp;

	for(my $i=0; $i<@stID; $i++)
	{
		if ($stID[$i] =~ /^G[0-9]+/)
		{
			
			$stTempID[$i] = $nGroup{$stID[$i]};
			$stID[$i] = $nGroup{$stID[$i]};
		}
	}

	my $stID = join(",", @stID);
	@stID = split /,/, $stID;

	my @stTempID1 = split /,/, $stTempID[0];
	my @stTempID2 = split /,/, $stTempID[1];

	for(my $i=0; $i<$#stTempID2; $i++)
	{
		for(my $j=$i+1; $j<@stTempID2;$j++)
		{
			$stTemp{"$stTempID2[$i],$stTempID2[$j]"}++;
			$stTemp{"$stTempID2[$j],$stTempID2[$i]"}++;
		}
	}
	for(my $i=0; $i<$#stTempID1; $i++)
	{
		for(my $j=$i+1; $j<@stTempID1;$j++)
		{
			$stTemp{"$stTempID1[$i],$stTempID1[$j]"}++;
			$stTemp{"$stTempID1[$j],$stTempID1[$i]"}++;
		}
	}

	for(my $i=0; $i<$#stID; $i++)
	{
		for(my $j=$i+1; $j<@stID; $j++)
		{
			next if ($stTemp{"$stID[$i],$stID[$j]"} ne "");
			next if ($stTemp{"$stID[$j],$stID[$i]"} ne "");

			$fKA = $fKA{"$stID[$i],$stID[$j]"};
			$fKS = $fKS{"$stID[$i],$stID[$j]"};
			$fKAKS = $fKAKS{"$stID[$i],$stID[$j]"};
#				$fKS = $fKS{"$stID[$i],$stID[$j]"};
			if($fKA eq "")
			{
				$fKA = $fKA{"$stID[$j],$stID[$i]"};
				$fKS = $fKS{"$stID[$j],$stID[$i]"};
				$fKAKS = $fKAKS{"$stID[$i],$stID[$j]"};
#				$fKS = $fKS{"$stID[$j],$stID[$i]"};
			}
			my $fKA = $fKA+0.000000001;
			my $fKS = $fKS+0.000000001;
			if($fKA =~ /[0-9]/)
			{
				push(@fKA,"$fKA");
			}
			if($fKS =~ /[0-9]/)
			{
				push(@fKS,"$fKS");
			}
			if($fKAKS =~ /[0-9]/)
			{
				push(@fKAKS,"$fKAKS");
			}
		}
	}
	my ($fKAKS,$fKA,$fKS);
	@fKA = sort{($a<=>$b)}(@fKA);
	@fKS = sort{($a<=>$b)}(@fKS);
	@fKAKS = sort{($a<=>$b)}(@fKAKS);

	for(my $i=0; $i<@fKA; $i++)
	{
		$fKA = $fKA+$fKA[$i];
	}
	for(my $i=0; $i<@fKS; $i++)
	{
		$fKS = $fKS+$fKS[$i];
	}
	for(my $i=0; $i<@fKAKS; $i++)
	{
		$fKAKS = $fKAKS+$fKAKS[$i];
	}

	if($stMethod eq "average")
	{
		$fKA = 1;
		$fKS = 1;

		$fKAKS = 1;
	}
	elsif($stMethod eq "single")
	{
		$fKA = $fKA[0];
		$fKS = $fKS[0];
		$fKAKS = $fKAKS[0];
	}
	elsif($stMethod eq "median")
	{
		if($#fKS%2 == 0)
		{
			my $nMedian = int ($#fKS/2);
			$fKA = $fKA[$nMedian];
			$fKS = $fKS[$nMedian];
		}
		else
		{
			$fKA = ($fKA[int($#fKS/2)] + $fKA[int($#fKS/2)+1/2]);
			$fKS = ($fKS[int($#fKS/2)] + $fKS[int($#fKS/2)+1/2]);
		}
		if($#fKAKS%2 == 0)
		{
			my $nMedian = int ($#fKAKS/2);
			$fKAKS = $fKAKS[$nMedian];
		}
		else
		{
			$fKAKS = ($fKAKS[int($#fKAKS/2)] + $fKAKS[int($#fKAKS/2)+1/2]);
		}

	}
	return($fKA,$fKS,$fKAKS);
}
