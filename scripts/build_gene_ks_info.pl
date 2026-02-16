use strict;

my $smooth_file = $ARGV[0];

my (%ks, %status, %preks, %prefix, %og);
open (FH, "$smooth_file");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	(my $subtree = $info[3]) =~ s/\(|\)//g;

	my @temp = split /_/, $info[0];
	my $prefix = $temp[0];
	my $og = $temp[1];

	my $preks = $info[4];
	my $smoothks = $info[6];

	my $status = "";
	if ($preks == $smoothks)
	{
		$status = "OK";
	}
	elsif ($preks > $smoothks)
	{	
		$status = "INVERSION_D";
	}
	elsif ($preks < $smoothks)
	{	
		$status = "INVERSION_U";
	}
	
	my $ks = $smoothks; 

	if ($ks == 0)
	{
		$status = "OK";
	}
	else
	{
		$status = "MIXED" if $info[7] eq "MIXED";
		$ks = "NA" if $status eq "MIXED";
	}

	my @temp = split /,/, $subtree;
	(my $leaf1 = $temp[0]) =~ s/:.*//g;
	(my $leaf2 = $temp[1]) =~ s/:.*//g;

	if ($leaf1 !~ /node/)
	{
		$preks{$leaf1} = $preks;
		$ks{$leaf1} = $ks;
		$status{$leaf1} = $status;
		$prefix{$leaf1} = $prefix;
		$og{$leaf1} = $og;
	}
	if ($leaf2 !~ /node/)
	{
		$preks{$leaf2} = $preks;
		$ks{$leaf2} = $ks;
		$status{$leaf2} = $status;
		$prefix{$leaf2} = $prefix;
		$og{$leaf2} = $og;
	}
}
close FH;

foreach my $gene_id (sort {$a cmp $b} keys %ks)
{
	$preks{$gene_id} = "NA" if $preks{$gene_id} eq "";
	print "$prefix{$gene_id}\t$og{$gene_id}\t$gene_id\tORIGINAL\t$preks{$gene_id}\n";
}
