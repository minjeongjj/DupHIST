use strict;

my $script_path = $ARGV[0];
my $pair_path = $ARGV[1];
my $pair_surfix = $ARGV[2];
my $prank_path = $ARGV[3];
my $kaks_path = $ARGV[4];
my $ks_method = $ARGV[5];
my $ks_genecode = $ARGV[6];
my $sleep_time = $ARGV[7];

my @glob = glob ("$pair_path/*$pair_surfix");

for (my $i=0; $i<@glob; $i++)
{
	(my $out_prefix = $glob[$i]) =~ s/\.$pair_surfix//g;
	print "$prank_path -d=$glob[$i] -f=fasta -codon -o=$out_prefix\n";
	print "sleep $sleep_time;\n";
	print "perl $script_path/fas_to_axt.pl $out_prefix.best.fas\n";
	print "$kaks_path -i $out_prefix.best.fas.axt -o $out_prefix.kaks -m $ks_method -c $ks_genecode\n";
}

