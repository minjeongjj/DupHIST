use strict;

my $stPrefix = $ARGV[0];
my $stPrank = $ARGV[1];
my $prankIter = $ARGV[2];
my $sleepTime = $ARGV[3];
my $ksCal = $ARGV[4];
my $ksMethod = $ARGV[5];
my $ksGenCode = $ARGV[6];
my $tempCDS = $ARGV[7];
my $tempBest = $ARGV[8];
my $tempAXT = $ARGV[9];
my $tempKaks = $ARGV[10];
my $path = $ARGV[11];

<<<<<<< HEAD
system("prank -d=$tempCDS/$stPrefix.CDS.fasta -f=fasta -codon -o=$tempBest/$stPrefix");
=======
system("$stPrank -d=$tempCDS/$stPrefix.CDS.fasta -f=fasta -codon -o=$tempBest/$stPrefix");
>>>>>>> 00c82b0... Release version 1.0.4: added dendrogram output, multithreading, and CDS triplet filter
#	-iterate=$prankIter");
sleep($sleepTime);
system("perl $path/parseFastaIntoAXT.pl $tempBest/$stPrefix.best.fas");
system("mv $tempBest/$stPrefix.best.fas.axt $tempAXT");
system("$ksCal -i $tempAXT/$stPrefix.best.fas.axt -o $tempKaks/$stPrefix.kaks -m $ksMethod -c $ksGenCode");

#print("$stPrank -d=$tempCDS/$stPrefix.CDS.fasta -f=fasta -codon -o=$tempBest/$stPrefix -iterate=$prankIter\n");
#print("perl $path/parseFastaIntoAXT.pl $tempBest/$stPrefix.best.fas\n");
#print("mv $tempBest/$stPrefix.best.fas.axt $tempAXT\n");
#print("$ksCal -i $tempAXT/$stPrefix.best.fas.axt -o $tempKaks/$stPrefix.kaks -m $ksMethod -c $ksGenCode\n");

