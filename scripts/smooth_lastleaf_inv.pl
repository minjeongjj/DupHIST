use strict;

my $geneks = $ARGV[0];
my $geneks_val = $ARGV[1];
my $pairks = $ARGV[2];
my $node_info = $ARGV[3];

my (%node, %sibling, %node_gene);
open (FH, "$node_info");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	(my $node_num = $info[1]) =~ s/node//g;
	my $type = $info[2];
	
	(my $subtree = $info[3]) =~ s/\(|\)//g;
	my @temp = split /,/, $subtree;
	(my $left = $temp[0]) =~ s/:.*//g;
	(my $right = $temp[1]) =~ s/:.*//g;

	$node{$left} = $node_num if $left !~ /node/;
	$node{$right} = $node_num if $right !~ /node/;

	if ($type =~ /gene-gene/)
	{	
		$sibling{$left} = $right;
		$sibling{$right} = $left;
	}

	$node_gene{$node_num} = "$left	$right";
}
close FH;

my (%ks, %reks, %revised);
open (FH, "$geneks");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $gene_id = $info[2];
	my $ks = $info[-1];

	$ks{$gene_id} = $ks;
	$reks{$gene_id} = $ks;
	
	if($info[-2] ne "ORIGINAL")
	{
		$revised{$gene_id} = $ks;
	}
}
close FH;

my (%child, %parent);
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

	next if $ks1 eq "NAN" || $ks2 eq "NAN";

	$child{$gene1}{$gene2} ++;
	$parent{$gene2}{$gene1} ++;
}
close FH;

my (%inv);
open (FH, "$geneks_val");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $gene1 = $info[1];
	my $gene2 = $info[2];

	if ($sibling{$gene2} ne "")
	{
		$inv{$gene2} ++;
		#print "$line\t$gene2\n";
	}
}
close FH;

my $LAMBDA = 10.0;	##
my $ALPHA = 10.0;	## $parent = 0
my $WRAW   = 1.0;   ## raw weight (w)
my $temp_ks_parent;
my $temp_ks_child;
my (%nbr);

my (%index);
foreach my $geneid (sort {$node{$a} <=> $node{$b} || $a cmp $b} keys %inv)
{
	my ($parent_ks_min);
	foreach my $parent (sort {$reks{$a} <=> $reks{$b}} keys %{$parent{$geneid}})
	{
		$parent_ks_min = $reks{$parent};
		$temp_ks_child = $parent_ks_min;
		
		$nbr{$geneid}{$parent} = 1;
		$nbr{$parent}{$geneid} = 1;
		
		last;
	}

	$temp_ks_parent = $ks{$geneid};
	
	my $sum_nbr = 0;
        my $n_nbr = 0;

	if (exists $nbr{$geneid}) 
	{
   			foreach my $n (sort keys %{$nbr{$geneid}}) 
		{
		        next if !defined $n;
		
		        my $v = (exists $reks{$n}) ? $reks{$n}
		              : (defined $ks{$n} && $ks{$n} ne 'NA') ? $ks{$n}
		              : undef;
		        next if !defined $v;
		
		        $sum_nbr += $v;
			$n_nbr++;
		}
	}
	
	$n_nbr +=1; #temp_parent
	
	my $A = $WRAW + $LAMBDA * $n_nbr + $ALPHA;
	
	my $B = $WRAW * $ks{$geneid} + $LAMBDA * $sum_nbr + $ALPHA * $temp_ks_parent;
	
	$sum_nbr += $temp_ks_parent; #temp_parent
	
	my $calculated_ks = $B/$A;
	my $a1 = abs($calculated_ks - $temp_ks_parent);
	my $a2 = abs($calculated_ks - $temp_ks_child);
	
	$a1 = sprintf("%.5f", $a1);
	$a1 = 0 + $a1;	
	$a2 = sprintf("%.5f", $a2);
	$a2 = 0 + $a2;	

	foreach my $parent (sort {$reks{$a} <=> $reks{$b}} keys %{$parent{$geneid}})
	{
		if($a1 <= $a2)
		{
			$reks{$geneid} = $ks{$parent} - $a1;
			$reks{$geneid} = 0 if $reks{$geneid} < 0;
		}
		else
		{
			$reks{$geneid} = $ks{$parent} - $a2;
			$reks{$geneid} = 0 if $reks{$geneid} < 0;
		}
		last;
	}

	next if(exists $revised{$geneid});
	$index{$geneid} = "LASTLEAF_D";
}

foreach my $nodenum (sort keys %node_gene)
{
	my @split = split/\t/,$node_gene{$nodenum};
	my $a1 = abs($ks{$split[0]} - $reks{$split[0]});
	my $a2 = abs($ks{$split[1]} - $reks{$split[1]});
	if($a1 < $a2)
	{
		$reks{$split[0]} = $reks{$split[0]};
		$reks{$split[1]} = $reks{$split[0]};
	}
	else
	{
		$reks{$split[0]} = $reks{$split[1]};
		$reks{$split[1]} = $reks{$split[1]};

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
	if ($index{$geneid} ne "")
	{
		$reindex = $index{$geneid};
		$reks = $reks{$geneid};
	}

	if ($reks eq "")
	{
		$reks = $reks{$sibling{$geneid}};
	}
	$reks = "NAN" if $reks eq "";

	print "$line\t$reindex\t$reks\n";
}
close FH;
close OUT;
