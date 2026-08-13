use strict;

my $input_path = $ARGV[0];
my $input_suffix = $ARGV[1];
my $val_suffix = $ARGV[2];

my @glob = glob ("$input_path/*$input_suffix");

my $divider = "-" x 30;

my $index = "";
for (my $i=0; $i<@glob; $i++)
{
	(my $out_prefix = $glob[$i]) =~ s/\.$input_suffix$//;

	my $temp = "$out_prefix.$val_suffix";
	#print "$glob[$i]\t$temp\n";

	if (-s $temp == 0)
	{
		print "ERROR $temp file does not exist\n";
		$index = "error";
	}
}

print "entire files have been conducted in $input_path/*$val_suffix\n" if $index eq "";
print "$divider\n";
