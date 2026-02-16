use strict;
use File::Basename;

my $pep_path = $ARGV[0]; 
my $out_dir = $ARGV[1];

my @glob = glob ("$pep_path/*pep.fa");

for (my $i=0; $i<@glob; $i++)
{
	my $pep_file = $glob[$i];

	my $file = basename ($pep_file);
	(my $out_file = $file) =~ s/\.pep.fa//;

	print "fftns --threads 1 $pep_file > $out_dir/$out_file.mafft\n";
}

