use strict;

my $aov_lsd_groups = $ARGV[0];
my $prefer_order = $ARGV[1]; 

my (%select);
open (File, $aov_lsd_groups);
while (my $line = <File>)
{
	chomp $line;
	next if $line =~ /ccc/;
	my @info = split " ", $line;

	(my $method_type = $info[0]) =~ s/[""]//g;
	(my $group = $info[2]) =~ s/[""]//g;

	next unless $group eq "a";

	$select{$method_type} ++;
}
close File;

my @prefer_order = split /,/, $prefer_order;
for (my $i=0; $i<@prefer_order; $i++)
{
	my $method_type = $prefer_order[$i];
	next if $select{$method_type} eq "";
	
	print "$method_type\n";
	last;
}
