use strict;

my $stInputDir = $ARGV[0];
my $stOutput = $ARGV[1];

my @stKSfiles = glob("$stInputDir/*/*.result*");

my %stVal;
open(OUT, ">$stOutput");
print OUT "#Prefix	Group	Gene1	Gene2	KS\n";
foreach my $file(@stKSfiles){
	my $stPrefix = (split /\_/, (split /\//, $file)[-1])[0];
	my $stGroup = (split /[\_|\.]+/, (split /\//, $file)[-1])[1];

	$stVal{"$stPrefix	$stGroup"}++;

	open(IN, $file);
	while(my $stLine = <IN>){
		chomp $stLine;
		my @stInfo = split /\t/, $stLine;

		my @stGenes = split /,/, $stInfo[5];

		#my $nMYA = $stInfo[2] / (2*$nRval{$stFamily{$stPrefix}}) / 1000000;
		#my $nMYA = $stInfo[1] / (2*$nRval{$stFamily{$stPrefix}}) / 1000000;

		#if($nRval{$stFamily{$stPrefix}} eq ""){
		#if($nMYA eq ""){
			#print "WARNING: $stPrefix	$stGroup	$stInfo[5]	$stFamily{$stPrefix}	$nRval{$stFamily{$stPrefix}}	has no MYA values\n";
			#	next;
			#}

		#print OUT "$stPrefix	$stGroup	$stGenes[0]	$stGenes[1]	$stInfo[2]	$nMYA\n";
		print OUT "$stPrefix	$stGroup	$stGenes[0]	$stGenes[1]	$stInfo[1]\n";

	}
	close(IN);
}

print scalar(keys %stVal)."\n";
