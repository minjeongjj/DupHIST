use strict;

my $stGroup = $ARGV[0]; # Total Group file, single
my $stCDS = $ARGV[1]; # Total Gene File, single
my $stOutDir = $ARGV[2];

my ($stName,$stSeq,$nGene)=("","","");
my (@stGroupInfo,@stGroupData,@stTemp);
my %stSeq;

open(DATA, "$stCDS");
while(my $stLine = <DATA>)
{
        chomp($stLine);
        if($stLine =~ /^>([^\s]+)/)
        {
                if($stSeq ne "")
                {
                        $stSeq{$stName} = $stSeq;
                        $stSeq = "";
                }
                $stName = $1;
        }
        else
        {
                $stSeq = $stSeq.$stLine;
        }
}
close(DATA);
$stSeq{$stName} = $stSeq;


open(DATA, "$stGroup");
@stGroupInfo = <DATA>;
chomp(@stGroupInfo);
close(DATA);

@stGroupInfo = sort
{
        ($a =~ /^([^\t]+)[\t]+/)[0] cmp ($b =~ /^([^\t]+)[\t]+/)[0] ||
        ($a =~ /^[^\t]+[\t]+([^\t]+)[\t]+/)[0] cmp ($b =~ /^[^\t]+[\t]+([^\t]+)[\t]+/)[0]
}@stGroupInfo;
#push(@stGroupInfo, "-");

for(my $i=0; $i<@stGroupInfo; $i++)
{
        my @stInfo = split /[\t]+/, $stGroupInfo[$i];
        my @stInfo2 = split /[\t]+/, $stGroupInfo[$i+1];
        if("$stInfo[0],$stInfo[1]" eq "$stInfo2[0],$stInfo2[1]")
        {
                push(@stTemp, $stInfo[2]);
        }
        else
        {
                push(@stTemp, $stInfo[2]);
                my $stTemp = join(",", @stTemp);
                my $nTemp = $#stTemp+1;
                $stTemp = "$nTemp,$stInfo[0]_$stInfo[1],$stTemp";
                push(@stGroupData, $stTemp);
                @stTemp = ();
        }
}
close(DATA);

for(my $i=0; $i<@stGroupData; $i++)
{
        my @stInfo = split /,/, $stGroupData[$i];
        my $stPrefix;

        my $nCnt = 0;
        my @stTempData = ();
	#        open(KS, ">$stOutDir/$stInfo[1].KS");
	#        open(TotalInfo, ">$stOutDir/$stInfo[1].Kaks");

        for(my $j=2;$j<@stInfo; $j++)
        {
                for(my $k=$j+1; $k<@stInfo; $k++)
                {
                        $stPrefix = "$stInfo[1].$j.$k";
                        if($nCnt == 0)
                        {
                                $nGene = $j;
                        }

			open(OUT, ">$stOutDir/$stPrefix.CDS.fasta");
			print OUT ">$stInfo[$j]\n$stSeq{$stInfo[$j]}\n>$stInfo[$k]\n$stSeq{$stInfo[$k]}\n";
                        #print "$j,$k   $stInfo[$j]     $stInfo[$k]\n";
			close(OUT);
			#system("mv $stPrefix.CDS.fasta $stOutDir")
		}
	}
}

#print("Make CDS Done\n");
#system("mv *.CDS.fasta $stOutDir/")
