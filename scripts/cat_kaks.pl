use strict;

my $algorithm_file = $ARGV[0];
my $input_path = $ARGV[1];
my $input_suffix = $ARGV[2];

open (FH, "$algorithm_file");
while (my $line = <FH>)
{
	chomp $line;
	next if $line =~ /^#/;
	my @info = split /\t/, $line;

	my $prefix_group = $info[0];

	print "cat $input_path/$prefix_group*kaks > $input_path/$prefix_group.catks\n";
}
close FH;


