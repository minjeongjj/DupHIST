use strict;

my $geneks = $ARGV[0];
my $pairks = $ARGV[1];

my (%ks);
open (FH, "$geneks");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $gene_id = $info[2];
	my $ks = $info[-1];

	$ks{$gene_id} = $ks;
}
close FH;

my (%child, %parent, %inversion);
open (FH, "$pairks");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $gene1 = $info[3];
	my $gene2 = $info[4];

	my $ks1 = $ks{$gene1};
	my $ks2 = $ks{$gene2};

	$child{$gene1}{$gene2} ++;
	$parent{$gene2}{$gene1} ++;

	if ($ks1 < $ks2)
	{
		$inversion{$gene1} ++;
		$inversion{$gene2} ++;
	}
}
close FH;

my $LAMBDA = 10.0;	##
my $ALPHA = 10.0;	## $parent = 0
my $WRAW   = 1.0;   ## raw weight (w)
my $temp_ks_parent;
my $temp_ks_child;
my (%reks,%max_child, %nbr);

foreach my $geneid (sort {(scalar keys %{$parent{$a}}) <=> (scalar keys %{$parent{$b}}) || (scalar keys %{$child{$b}}) <=> (scalar keys %{$child{$a}})} keys %child)
{
	my $child_num = scalar keys %{$child{$geneid}};
	my $parent_num = scalar keys %{$parent{$geneid}};

	if ($parent_num == 0 && $inversion{$geneid} ne "")
	{
		
		foreach my $child (sort {$ks{$b} <=> $ks{$a}} keys %{$child{$geneid}})
		{
			$temp_ks_child = $ks{$geneid};  ##
			$nbr{$geneid}{$child} = 1;
			$nbr{$child}{$geneid} = 1;
			$temp_ks_parent = $ks{$child};
			last;
		}

		my $sum_nbr = 0;
	        my $n_nbr = 0;

		if (exists $nbr{$geneid}) 
		{
    			foreach my $n (sort keys %{$nbr{$geneid}}) 
			{
			        next if !defined $n;
			
			        my $v = (exists $reks{$n}) ? $reks{$n}
			              : (defined $ks{$n} && $ks{$n} ne 'NAN') ? $ks{$n}
			              : undef;
			        next if !defined $v;
			
			        $sum_nbr += $v;
				$n_nbr++;
			}
		}
		
		$n_nbr +=1; #temp_child
		my $A = $WRAW + $LAMBDA * $n_nbr + $ALPHA;
		my $B = $WRAW * $ks{$geneid} + $LAMBDA * $sum_nbr + $ALPHA * $temp_ks_parent;
		
		$sum_nbr += $temp_ks_child; #temp_child
		my $calculated_ks = $B/$A;
		my $a1 = abs($calculated_ks - $temp_ks_parent);
		my $a2 = abs($calculated_ks - $temp_ks_child);
		
		$a1 = sprintf("%.5f", $a1);
		$a1 = 0 + $a1;	
		$a2 = sprintf("%.5f", $a2);
		$a2 = 0 + $a2;	

		foreach my $child (sort {$ks{$b} <=> $ks{$a}} keys %{$child{$geneid}})
		{
			if($a1 <= $a2)
			{
				$reks{$geneid} = $ks{$child} + $a1;
			}
			else
			{
				$reks{$geneid} = $ks{$child} + $a2;
			}
			last;
		}
	}
}

open (FH, "$geneks");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $geneid = $info[2];
	my $ks = $info[-1];
	my $index = $info[-2];

	my $reks = $ks;
	my $reindex = $index;

	if ($reks{$geneid} ne "")
	{
		$reks = $reks{$geneid};
		$reindex = "PARENT_U";
	}
	$reks = "NAN" if $reks eq "";

	print "$line\t$reindex\t$reks\n";
}
close FH;


