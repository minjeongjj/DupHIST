use strict;
use File::Basename;

my $algorithm_file = $ARGV[0];
my $file_path = $ARGV[1];
my $file_suffix = $ARGV[2];

my @glob = glob ("$file_path/*$file_suffix");

my (%done);
for (my $i=0; $i<@glob; $i++)
{
	my $file = basename ($glob[$i]);
	(my $prefix_group = $file) =~ s/\..*//g;

	$done{$prefix_group} ++;
}

my $divider = "-" x 30;

#print "$divider\n";

my $index = "";
open (FH, "$algorithm_file");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $prefix_group = $info[0];

	next if $done{$prefix_group} ne "";

	print "ERROR $prefix_group.$file_suffix is not exist in $file_path/*$file_suffix\n";

	$index = "error";
}
close FH;

if ($index eq "")
{
	print "entire files have been conducted in $file_path/*$file_suffix\n";
}

print "$divider\n";
