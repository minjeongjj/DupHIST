use strict;

my $input_dir = $ARGV[0];
my $sh_prefix = $ARGV[1];

my @glob = glob ("$input_dir/$sh_prefix*[0-9].sh");

for (my $i=0; $i<@glob; $i++)
{
	print "sh $glob[$i] &\n";
}

print "wait;\n";
