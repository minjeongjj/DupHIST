use strict;

my $inputpath = $ARGV[0];
my $stOutDir = $ARGV[1];
my $matrixpath = $ARGV[2];
my $script = $ARGV[3];
my $groupinfo = $ARGV[4];
my @stGroupInfo = glob("$groupinfo/*.txt");
my $groupPrefix;
my @stkaks;
#my @stTempData;
my $nGene1;
my $nGene2;

for(my $i=0; $i<@stGroupInfo; $i++)
{
	$groupPrefix = $stGroupInfo[$i];
       	print "$groupPrefix\n";
	$groupPrefix =~ s/.txt//g;
	my @stTemp = split('/',$groupPrefix);
	$groupPrefix = $stTemp[3];
	my @stTemp2 = split('_',$groupPrefix);
	my $species = $stTemp2[0];
	if ( -d "$matrixpath/$species")
	{
	}
	else
	{
		mkdir "$matrixpath/$species";
	}
	@stkaks = glob("$inputpath/$groupPrefix*.kaks");
	print "$groupPrefix\t$#stkaks\n";	
	open(KS, ">$stOutDir/$groupPrefix.KS");
        open(TotalInfo, ">$stOutDir/$groupPrefix.Kaks");
	my @stTempData;	
	for(my $j=0; $j<@stkaks; $j++)
	{
		#print "$stkaks[$j]\n";
		@stTemp = split('\.',$stkaks[$j]);
		$nGene1 = $stTemp[1]-1;
		#print "$nGene1\n";
		$nGene2 = $stTemp[2]-1;
		open(DATA, $stkaks[$j]);
	 	while(my $stLine = <DATA>)
		{
			chomp($stLine);
                        next if ($stLine =~ /Method/);
                        my @stInfo = split /[\s\t]+/, $stLine;

                        print TotalInfo "$stLine\n";

                        if($stInfo[3] eq "NA")
                        {
                        	$stInfo[3] = 0;
                        }
                        elsif($stInfo[3] !~ /[0-9]/)
                        {
                                $stInfo[3] = 100;
                        }
                        my $stTempData = "$nGene1\t$nGene2\t$stInfo[3]\t$stInfo[0]";
                        push(@stTempData, $stTempData);
                 }
		 close(DATA);
		 @stTempData = sort 
		 { 
			 ($a =~ /^([^\t]+)[\t]+/)[0] <=> ($b =~ /^([^\t]+)[\t]+/)[0] || 
			 ($a =~ /^[^\t]+[\t]+([^\t]+)[\t]+/)[0] <=> ($b =~ /^[^\t]+[\t]+([^\t]+)[\t]+/)[0]
		 } @stTempData;
	}
	
	for(my $k=0; $k<@stTempData; $k++)
        {
                print KS "$stTempData[$k]\n";
        }
        close(KS);
	my $nFilesize = -s "$stOutDir/$groupPrefix.KS";
        if($nFilesize < 1)
        {
                system("rm -rf $stOutDir/$groupPrefix.KS");
        }
        if($nFilesize > 0)
        {
                system("perl $script/MakeRDistFormat.pl $stOutDir/$groupPrefix.KS > $matrixpath/$species/$groupPrefix.matrix");
        }
}
