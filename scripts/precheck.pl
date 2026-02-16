#!/usr/bin/perl

use strict;
use File::Basename;

my $cds_file = $ARGV[0];
my $pep_file = $ARGV[1];
my $group_info = $ARGV[2];

my $divider = "=" x 30;

my (%species, %group, %species_group, %group_gene);
open (Info, "$group_info");
while (my $line = <Info>)
{
	chomp $line;
	my @info = split /\t/, $line;

	my $species_name = $info[0];
	my $group_name = $info[1];
	my $gene_id = $info[2];

	$species{$species_name} ++;
	$group{$group_name} ++;

	my $temp = "$species_name\t$group_name";
	$species_group{$temp} ++;

	$group_gene{$gene_id} ++;
}
close Info;

my $cnt = "";
my $total_cnt = "";
my $temp_cnt1 = "";
foreach my $species_name (sort {$a cmp $b} keys %species)
{
	if ($species_name =~ /_/)
	{
		$cnt ++;
		$total_cnt ++;
		$temp_cnt1 ++;
		if ($cnt == 1)
		{
			print "$divider\n";
			print "[INVALID FORMAT] Detected underscores \"_\" in species abbreviation or group names.\n";
			print "In 'duphist', the underscore \"_\" is used to combine species and group names into a unique identifier (species_groupid).\n";
			print "Please remove underscores \"_\" from the following entries.\n";
			#print "$divider\n";
			print "\n";
		}

		if ($temp_cnt1 == 1)
		{
			print "-- Species abbreviation:\n";
		}

		print "$species_name\n";
	}
}

my $temp_cnt2 = "";
foreach my $group_name (sort {$a cmp $b} keys %group)
{
	if ($group_name =~ /_/)
	{
		$cnt ++;
		$total_cnt ++;
		$temp_cnt2 ++;
		if ($cnt == 1)
		{
			print "$divider\n";
			print "[INVALID FORMAT] Detected underscores (_) in species abbreviation or group names.\n";
			print "Please remove underscores from the following entries to ensure compatibility with 'duphist' indexing (species_groupid format):\n";
			#print "$divider\n";
			print "\n";
		}

		if ($temp_cnt2 == 1)
		{
			print "\n" if ($temp_cnt1 ne "");
			print "-- Group names:\n";
		}

		print "$group_name\n";
	}
}

my $cnt = "";
my $temp_cnt = "";
foreach my $data (sort {$a cmp $b} keys %species_group)
{
	if ($species_group{$data} == 1)
	{
		$cnt ++;
		$total_cnt ++;
		$temp_cnt ++;
		if ($cnt == 1)
		{
			print "\n" if $total_cnt > 1;
			print "$divider\n";
			print "[INVALID FORMAT] Only one gene found for some species_group combinations.\n";
			print "Each species_group must contain at least two genes to run 'duphist'.\n";
			print "Please remove or merge the following invalid entries:\n";
			#print "$divider\n";
			print "\n";
		}

		if ($temp_cnt == 1)
		{	
			print "-- Species with group:\n";
		}

		print "$data\n";
	}
}

my ($gene_id, %cds);
open (CDS, "$cds_file");
while (my $line = <CDS>)
{
	chomp $line;
	if ($line =~ />([^\s\t]+)/)
	{
		$gene_id = $1;
	}
	else
	{
		$cds{$gene_id} .= $line;
	}
}
close CDS;

my $cnt = "";
my $group_gene_cnt = scalar keys %group_gene;
my $cds_gene_cnt = scalar keys %cds;
if ($group_gene_cnt != $cds_gene_cnt)
{
	$cnt ++;
	$total_cnt ++;
	if ($cnt == 1)
	{
		print "\n" if $total_cnt > 1;
		print "$divider\n";
		print "[INVALID FORMAT] Inconsistent gene entries between group info and CDS file.\n";
		print "'duphist' requires every gene listed in the group info file to have a corresponding CDS entry.\n";
		print "Synchronization check failed due to missing or unmatched gene IDs.\n";
		print "Please review the discrepancies below.\n";
		#print "$divider\n";
		print "\n";
	}

	print "Total genes in group info: $group_gene_cnt\n";
	print "Total genes with CDS entries: $cds_gene_cnt\n";
}

my $cnt = "";
my $temp_cnt1 = "";
foreach my $gene_id (sort {$a cmp $b} keys %group_gene)
{	
	if ($cds{$gene_id} eq "")
	{
		$cnt ++;
		$total_cnt ++;
		if ($cnt == 1)
		{
			print "\n" if $total_cnt > 1;
			print "$divider\n";
			print "[INVALID FORMAT] Gene synchronization failed between group info and CDS file.\n";
			print "Before running, 'duphist' checks if all gene IDs are matched across input files.\n";
			print "The following gene entries are inconsistent and must be removed or corrected.\n";
			#print "$divider\n";
			print "\n";
		}

		$temp_cnt1 ++;
		if ($temp_cnt1 == 1)
		{
			print "-- Gene IDs found in group info but missing in CDS:\n";
		}
	
		print "$gene_id\n";
	}
}

my $temp_cnt2 = "";
foreach my $gene_id (sort {$a cmp $b} keys %cds)
{	
	if ($group_gene{$gene_id} eq "")
	{
		$cnt ++;
		$total_cnt ++;
		if ($cnt == 1)
		{
			print "\n" if $total_cnt > 1;
			print "$divider\n";
			print "[INVALID FORMAT] Gene synchronization failed between group info and CDS file.\n";
			print "Before running, 'duphist' checks if all gene IDs are matched across input files.\n";
			print "The following gene entries are inconsistent and must be removed or corrected.\n";
			#print "$divider\n";
			print "\n";
		}

		$temp_cnt2 ++;
		if ($temp_cnt2 == 1)
		{
			print "\n" if ($temp_cnt1 ne "");

			print "-- Gene IDs found in CDS file but missing in group info:\n";
		}

		print "$gene_id\n";
	}
}

if ($total_cnt ne "")
{
	my $divider = "=" x 30;

	print "\n" if $total_cnt > 1;
	print "$divider\n";
	print "Please fix the issues above and rerun duphist.\n";
	print "$divider\n";
}


my ($gene_id, %pep);
open (PEP, "$pep_file");
while (my $line = <PEP>)
{
	chomp $line;
	if ($line =~ />([^\s\t]+)/)
	{
		$gene_id = $1;
	}
	else
	{
		$pep{$gene_id} .= $line;
	}
}
close PEP;

my $cnt = "";
my $group_gene_cnt = scalar keys %group_gene;
my $pep_gene_cnt = scalar keys %pep;
if ($group_gene_cnt != $pep_gene_cnt)
{
	$cnt ++;
	$total_cnt ++;
	if ($cnt == 1)
	{
		print "\n" if $total_cnt > 1;
		print "$divider\n";
		print "[INVALID FORMAT] Inconsistent gene entries between group info and PEP file.\n";
		print "'duphist' requires every gene listed in the group info file to have a corresponding PEP entry.\n";
		print "Synchronization check failed due to missing or unmatched gene IDs.\n";
		print "Please review the discrepancies below.\n";
		#print "$divider\n";
		print "\n";
	}

	print "Total genes in group info: $group_gene_cnt\n";
	print "Total genes with PEP entries: $pep_gene_cnt\n";
}

my $cnt = "";
my $temp_cnt1 = "";
foreach my $gene_id (sort {$a cmp $b} keys %group_gene)
{	
	if ($pep{$gene_id} eq "")
	{
		$cnt ++;
		$total_cnt ++;
		if ($cnt == 1)
		{
			print "\n" if $total_cnt > 1;
			print "$divider\n";
			print "[INVALID FORMAT] Gene synchronization failed between group info and PEP file.\n";
			print "Before running, 'duphist' checks if all gene IDs are matched across input files.\n";
			print "The following gene entries are inconsistent and must be removed or corrected.\n";
			#print "$divider\n";
			print "\n";
		}

		$temp_cnt1 ++;
		if ($temp_cnt1 == 1)
		{
			print "-- Gene IDs found in group info but missing in PEP:\n";
		}
	
		print "$gene_id\n";
	}
}

my $temp_cnt2 = "";
foreach my $gene_id (sort {$a cmp $b} keys %pep)
{	
	if ($group_gene{$gene_id} eq "")
	{
		$cnt ++;
		$total_cnt ++;
		if ($cnt == 1)
		{
			print "\n" if $total_cnt > 1;
			print "$divider\n";
			print "[INVALID FORMAT] Gene synchronization failed between group info and PEP file.\n";
			print "Before running, 'duphist' checks if all gene IDs are matched across input files.\n";
			print "The following gene entries are inconsistent and must be removed or corrected.\n";
			#print "$divider\n";
			print "\n";
		}

		$temp_cnt2 ++;
		if ($temp_cnt2 == 1)
		{
			print "\n" if ($temp_cnt1 ne "");

			print "-- Gene IDs found in PEP file but missing in group info:\n";
		}

		print "$gene_id\n";
	}
}

if ($total_cnt ne "")
{
	my $divider = "=" x 30;

	print "\n" if $total_cnt > 1;
	print "$divider\n";
	print "Please fix the issues above and rerun duphist.\n";
	print "$divider\n";
}
