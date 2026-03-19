use strict;
use File::Basename;

my $pep_path = $ARGV[0]; 
my $mafft_path = $ARGV[1];
my $out_dir = $ARGV[2];

my @glob = glob ("$pep_path/*pep.fa");

for (my $i=0; $i<@glob; $i++)
{
	my $pep_file = $glob[$i];

	my $file = basename ($pep_file);
	(my $out_file = $file) =~ s/\.pep.fa//;

	print "$mafft_path --threads 1 $pep_file > $out_dir/$out_file.mafft\n";
}

