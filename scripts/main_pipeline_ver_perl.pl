use strict;
use FindBin;

use Config::Tiny;
use Data::Dumper qw(Dumper);
use Cwd 'abs_path';
use List::Util qw/ min max /;

use POSIX qw(strftime);

my $filename = shift or die "Usage: $0 FILENAME\n";
my $config = Config::Tiny->read( $filename, 'utf8' );

my $script_path = $FindBin::Bin;

my $temp_path = "$config->{required_option}{output_dir}/$config->{Result}{temp_path}";
my $temp_pep = "$temp_path/pep_for_align";
my $temp_msa = "$temp_path/msa";
my $temp_sh = "$temp_path/temp_sh";
my $temp_tree = "$temp_path/temp_tree";
my $temp_raw_nwk = "$temp_path/temp_raw_nwk";
my $temp_multi = "$temp_path/temp_multi";
my $temp_replace = "$temp_path/temp_replace";
my $temp_revise_nwk = "$temp_path/revised_nwk";
my $temp_cds = "$temp_path/cds_prank_ks";
my $temp_smooth = "$temp_path/smoothing";

system ("perl $script_path/precheck.pl $config->{required_option}{cds_fasta} $config->{required_option}{pep_fasta} $config->{required_option}{group_info} > duplication_precheck.log");

if (-s "duplication_precheck.log")
{
	my $divider = "=" x 30;
	die "$divider\n[FATAL] Precheck failed: invalid input files.\nPlease correct the problems in duplication_precheck.log before running duphist.\n$divider\n";
}

## Read log file & Continue
my $step;
if (not(-f "duplication_progress.log"))
{
	$step = 1;
}
else
{
	open(LOG, "duplication_progress.log");
	while(my $stLine = <LOG>)
	{
		chomp $stLine;
		if($stLine =~ /DupHIST Step1/)
		{
			$step = 2;
		}
		elsif($stLine =~ /DupHIST Step2/)
		{
			$step = 3;
		}
		elsif($stLine =~ /Matrix file Done/)
		{
			$step = 4;
		}
		elsif($stLine =~ /H-clustering Done/)
		{
			print "Duplication time Calculation is Done\n";
			print "If you want to do again, remove log file\n";
		}
	}
	close(LOG);
}

system("mkdir -p $config->{required_option}{output_dir}");
system("mkdir -p $temp_pep");
system("mkdir -p $temp_msa");
system("mkdir -p $temp_sh");
system("mkdir -p $temp_tree");
system("mkdir -p $temp_raw_nwk");
system("mkdir -p $temp_multi");
system("mkdir -p $temp_replace");
system("mkdir -p $temp_revise_nwk");
system("mkdir -p $temp_cds");
system("mkdir -p $temp_smooth");

my $total_start_time = time();

my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
$year += 1900;
$mon += 1;
if ($step == 1)
{
	open(LOG, ">duplication_progress.log");
	print LOG "\n\n$year-$mon-$mday    Duplication time calculation Start..\n\n\n\n";
	close(LOG);

	my $start_time = time();

	## split pep by 'prefix_group'
	system("perl $script_path/prepare_pep.pl $config->{required_option}{group_info} $config->{required_option}{pep_fasta} $config->{ML_option}{size_threshold} $temp_pep");

	system ("perl $script_path/validate_run.pl $temp_sh/../hybrid_algorithm.info $temp_pep pep.fa > duplication_validation.log");

	
	## run msa
	system ("perl $script_path/bulk_msa.pl $temp_pep $temp_msa > $temp_sh/total_msa.sh");

	my @temp = glob ("$temp_pep/*pep.fa");
	my $total = scalar keys @temp;
	my $num = int ($total / $config->{Thread}{thread_num}) + 1;
	my $num_perl = $num * 3;

	system ("split -d -l $num --additional-suffix=.sh \"$temp_sh\/total_msa.sh\" \"$temp_sh\/temp_msa\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_msa > $temp_sh/Run_msa.sh");

	system("sh $temp_sh/Run_msa.sh >$temp_sh/Run_msa.log 2>$temp_sh/Run_msa.log2");	## bulk
	system ("perl $script_path/validate_run.pl $temp_sh/../hybrid_algorithm.info $temp_msa mafft >> duplication_validation.log");


	## run tree by hybrid ml
	system ("perl $script_path/bulk_tree.pl $temp_sh/../hybrid_algorithm.info $temp_msa $temp_tree > $temp_sh/total_tree.sh");

	system ("split -d -l $num --additional-suffix=.sh \"$temp_sh\/total_tree.sh\" \"$temp_sh\/temp_tree\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_tree > $temp_sh/Run_tree.sh");

	system("sh $temp_sh/Run_tree.sh >$temp_sh/Run_tree.log 2>$temp_sh/Run_tree.log2");	## bulk


	## copy and rename nwk file
	system ("perl $script_path/copy_tree.pl $temp_tree $temp_raw_nwk > $temp_sh/total_copy_tree.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_copy_tree.sh\" \"$temp_sh\/temp_copy_tree\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_copy_tree > $temp_sh/Run_copy_tree.sh");
	
	system ("sh $temp_sh/Run_copy_tree.sh >$temp_sh/Run_copy_tree.sh.log 2>$temp_sh/Run_copy_tree.sh.log2");	## bulk
	system ("perl $script_path/validate_run.pl $temp_sh/../hybrid_algorithm.info $temp_raw_nwk nwk >> duplication_validation.log");
	
	
	## detect multiple pair
	system ("perl $script_path/bulk_index_node.pl $temp_raw_nwk $script_path > $temp_sh/total_index_raw.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_index_raw.sh\" \"$temp_sh\/temp_index_raw\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_index_raw > $temp_sh/Run_index_raw.sh");

	system ("sh $temp_sh/Run_index_raw.sh >$temp_sh/Run_index_raw.log 2>$temp_sh/Run_index_raw.log2");	## bulk
	system ("perl $script_path/validate_run.pl $temp_sh/../hybrid_algorithm.info $temp_raw_nwk nodeinfo >> duplication_validation.log");


	## extract cds from multiple pair
	system ("perl $script_path/bulk_extract_multipair_cds.pl $temp_raw_nwk $script_path $config->{required_option}{cds_fasta} $temp_multi > $temp_sh/total_multi_cds.sh");
	
	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_multi_cds.sh\" \"$temp_sh\/temp_multi_cds\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_multi_cds > $temp_sh/Run_multi_cds.sh");

	system ("sh $temp_sh/Run_multi_cds.sh >$temp_sh/Run_multi_cds.log 2>$temp_sh/Run_multi_cds.log2");	## bulk


	## run prank ks for multiple pair
	system ("perl $script_path/bulk_prank_kaks.pl $script_path $temp_multi cds.fa $config->{program_path}{prank_path} $config->{program_path}{kaks_path} $config->{kaks_cal_option}{method} $config->{kaks_cal_option}{genetic_code} $config->{PRANK_option}{sleep_time} > $temp_sh/total_multi_ks.sh");

	my $num_ks = $num * 4;
	
	system ("split -d -l $num_ks --additional-suffix=.sh \"$temp_sh\/total_multi_ks.sh\" \"$temp_sh\/temp_multi_ks\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_multi_ks > $temp_sh/Run_multi_ks.sh");
	
	system ("sh $temp_sh/Run_multi_ks.sh >$temp_sh/Run_multi_ks.log 2>$temp_sh/Run_multi_ks.log2");	## bulk	
	system ("rm -rf tmpdirprank*");
	
	system ("perl $script_path/validate_run_out.pl $temp_multi cds.fa kaks >> duplication_validation.log");


	## build matrix and run hcluster for multiple pair
	system ("perl $script_path/bulk_ks_to_matrix.pl $temp_multi combi $script_path > $temp_sh/total_multi_matrix.sh");
	
	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_multi_matrix.sh\" \"$temp_sh\/temp_multi_matrix\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_multi_matrix > $temp_sh/Run_multi_matrix.sh");

	system ("sh $temp_sh/Run_multi_matrix.sh >$temp_sh/Run_multi_matrix.log 2>$temp_sh/Run_multi_matrix.log2");	## bulk

	system ("perl $script_path/validate_run_out.pl $temp_multi combi matrix >> duplication_validation.log");
	

	## run hcluster for multiple pair
	system ("perl $script_path/bulk_hcluster_rscript.pl $temp_multi matrix $script_path > $temp_sh/total_multi_hcluster.sh");

	system ("split -d -l $num --additional-suffix=.sh \"$temp_sh\/total_multi_hcluster.sh\" \"$temp_sh\/temp_multi_hcluster\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_multi_hcluster > $temp_sh/Run_multi_hcluster.sh");

	system ("sh $temp_sh/Run_multi_hcluster.sh >$temp_sh/Run_multi_hcluster.log 2>$temp_sh/Run_multi_hcluster.log2");    ## bulk
	
	system ("perl $script_path/validate_run_out.pl $temp_multi matrix nwk >> duplication_validation.log");

	
	## replace multiple pair subtree nwk and build revised nwk
	system ("perl $script_path/bulk_replace_multipair_hcluster.pl $temp_raw_nwk nodeinfo $temp_multi $temp_replace $script_path > $temp_sh/total_multi_temp.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_multi_temp.sh\" \"$temp_sh\/temp_multi_temp\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_multi_temp > $temp_sh/Run_multi_temp.sh");

	system ("sh $temp_sh/Run_multi_temp.sh >$temp_sh/Run_multi_temp.log 2>$temp_sh/Run_multi_temp.log2");    ## bulk
	
	system ("perl $script_path/bulk_lift_gene_in_nodeinfo.pl $temp_replace nodeinfo_temp $script_path > $temp_sh/total_multi_noderev.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_multi_noderev.sh\" \"$temp_sh\/temp_multi_noderev\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_multi_noderev > $temp_sh/Run_multi_noderev.sh");

	system ("sh $temp_sh/Run_multi_noderev.sh >$temp_sh/Run_multi_noderev.log 2>$temp_sh/Run_multi_noderev.log2");    ## bulk
	
	system ("perl $script_path/bulk_nodeinfo_to_newick.pl $temp_replace nodeinfo_revised $temp_revise_nwk scripts > $temp_sh/total_multi_revise.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_multi_revise.sh\" \"$temp_sh\/temp_multi_revise\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_multi_revise > $temp_sh/Run_multi_revise.sh");

	system ("sh $temp_sh/Run_multi_revise.sh >$temp_sh/Run_multi_revise.log 2>$temp_sh/Run_multi_revise.log2");    ## bulk

	system ("perl $script_path/validate_run.pl $temp_sh/../hybrid_algorithm.info $temp_revise_nwk nwk >> duplication_validation.log");

	system ("perl $script_path/bulk_validate_genecount.pl $temp_raw_nwk nwk $temp_revise_nwk $script_path > $temp_sh/total_multi_val.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_multi_val.sh\" \"$temp_sh\/temp_multi_val\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_multi_val > $temp_sh/Run_multi_val.sh");

	system ("sh $temp_sh/Run_multi_val.sh >$temp_sh/Run_multi_val.log 2>$temp_sh/Run_multi_val.log2");	## bulk
	system ("find $temp_revise_nwk -type f -exec grep \"MISMATCH\" {} + >> duplication_validation.log");

	my @tmp = glob ("$temp_revise_nwk/*nwk");
	my $output_count = scalar keys @tmp;

	######### print log file #########
	my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);

	my $total_sec = time() - $start_time;
	my $hr  = int($total_sec / 3600);
	my $min = int(($total_sec % 3600) / 60);
	my $sec = $total_sec % 60;

	my $time_string = sprintf("%d hr %d min %d sec", $hr, $min, $sec);

	open (OUT, ">>duplication_progress.log");
	print OUT "------------------------------------------------------------\n";
	print OUT "[INFO] $timestamp - DupHIST Step1. Inferred duplication hierarchy using Hybrid ML\n";
	print OUT "   - Task:        Hybrid-ML Tree Construction\n";
	print OUT "   - Input:       $temp_pep/*pep.fa\n";   
	print OUT "   - Output:      $temp_revise_nwk/*nwk\n";  
	print OUT "   - Summary:     Total $output_count .nwk files generated successfully\n";
	print OUT "   - Status:      COMPLETED SUCCESSFULLY ✔\n";
	print OUT "   - Runtime:     $time_string\n";
	print OUT "------------------------------------------------------------\n";
	close (OUT);
	##################################
	
	$step = 2;
}

if ($step == 2)
{
	my $start_time = time();

	my @temp = glob ("$temp_revise_nwk/*nwk");
	my $total = scalar keys @temp;
	my $num = int ($total / $config->{Thread}{thread_num}) + 1;
	my $num_perl = $num * 3;

	## index node of nwk
	system ("perl $script_path/bulk_index_node.pl $temp_revise_nwk $script_path > $temp_sh/total_index_node.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_index_node.sh\" \"$temp_sh\/temp_index_node\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_index_node > $temp_sh/Run_index_node.sh");

	system ("sh $temp_sh/Run_index_node.sh >$temp_sh/Run_index_node.log 2>$temp_sh/Run_index_node.log2");	## bulk

	system ("perl $script_path/validate_run.pl $temp_sh/../hybrid_algorithm.info $temp_revise_nwk nodeinfo >> duplication_validation.log");
	system ("find $temp_revise_nwk -type f -exec grep \"gene-gene-multi\" {} + >> duplication_validation.log");


	## build pair info for ks calculation
	system ("perl $script_path/bulk_build_pair.pl $temp_revise_nwk nodeinfo $script_path > $temp_sh/total_rev_pair.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_rev_pair.sh\" \"$temp_sh\/temp_rev_pair\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_rev_pair > $temp_sh/Run_rev_pair.sh");

	system ("sh $temp_sh/Run_rev_pair.sh >$temp_sh/Run_rev_pair.log 2>$temp_sh/Run_rev_pair.log2");  ## bulk
	
	system ("perl $script_path/validate_run_out.pl $temp_revise_nwk nwk pair >> duplication_validation.log");

	## extract cds pair for ks calculation
	system ("perl $script_path/bulk_extract_pair_cds.pl $temp_revise_nwk pair $config->{required_option}{cds_fasta} $temp_cds $script_path > $temp_sh/total_rev_cds.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_rev_cds.sh\" \"$temp_sh\/temp_rev_cds\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_rev_cds > $temp_sh/Run_rev_cds.sh");

	system ("sh $temp_sh/Run_rev_cds.sh >$temp_sh/Run_rev_cds.log 2>$temp_sh/Run_rev_cds.log2");  ## bulk
	
	system ("cat $temp_revise_nwk/*pair > $temp_revise_nwk/pair_cat");
	system ("perl $script_path/validate_cdsnum.pl $temp_revise_nwk/pair_cat $temp_cds cds.fa >> duplication_validation.log");

	## run prank and kaks_calculator	
	system ("perl $script_path/bulk_prank_kaks.pl $script_path $temp_cds cds.fa $config->{program_path}{prank_path} $config->{program_path}{kaks_path} $config->{kaks_cal_option}{method} $config->{kaks_cal_option}{genetic_code} $config->{PRANK_option}{sleep_time} > $temp_sh/total_rev_ks.sh");


	my @temp = glob ("$temp_cds/*cds.fa");
	my $total = scalar keys @temp;
	my $num = int ($total / $config->{Thread}{thread_num}) + 1;
	my $num_ks = $num * 4;

	system ("split -d -l $num_ks --additional-suffix=.sh \"$temp_sh\/total_rev_ks.sh\" \"$temp_sh\/temp_rev_ks\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_rev_ks > $temp_sh/Run_rev_ks.sh");

	system ("sh $temp_sh/Run_rev_ks.sh >$temp_sh/Run_rev_ks.log 2>$temp_sh/Run_rev_ks.log2");        ## bulk
	system ("rm -rf tmpdirprank*");

	system ("perl $script_path/validate_run_out.pl $temp_cds cds.fa kaks >> duplication_validation.log");

	## cat kaks and index pairks
	system ("perl $script_path/cat_kaks.pl $temp_sh/../hybrid_algorithm.info $temp_cds kaks > $temp_sh/total_rev_cat.sh");

	my @temp = glob ("$temp_revise_nwk/*nwk");
	my $total = scalar keys @temp;
	my $num = int ($total / $config->{Thread}{thread_num}) + 1;
	my $num_perl = $num * 3;

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_rev_cat.sh\" \"$temp_sh\/temp_rev_cat\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_rev_cat > $temp_sh/Run_rev_cat.sh");

	system ("sh $temp_sh/Run_rev_cat.sh >$temp_sh/Run_rev_cat.log 2>$temp_sh/Run_rev_cat.log2");        ## bulk
	
	system ("perl $script_path/validate_run.pl $temp_sh/../hybrid_algorithm.info $temp_cds catks >> duplication_validation.log");
	

	system ("perl $script_path/bulk_index_pairks.pl $temp_cds catks $temp_revise_nwk $script_path > $temp_sh/total_rev_pairks.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_rev_pairks.sh\" \"$temp_sh\/temp_rev_pairks\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_rev_pairks > $temp_sh/Run_rev_pairks.sh");

	system ("sh $temp_sh/Run_rev_pairks.sh >$temp_sh/Run_rev_pairks.log 2>$temp_sh/Run_rev_pairks.log2");        ## bulk

	system ("perl $script_path/validate_run_out.pl $temp_revise_nwk nwk pairks >> duplication_validation.log");


	my @tmp = glob ("$temp_revise_nwk/*pairks");
	my $output_count = scalar keys @tmp;

	######### print log file #########
	my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);

	my $total_sec = time() - $start_time;
	my $hr  = int($total_sec / 3600);
	my $min = int(($total_sec % 3600) / 60);
	my $sec = $total_sec % 60;

	my $time_string = sprintf("%d hr %d min %d sec", $hr, $min, $sec);

	open (OUT, ">>duplication_progress.log");
	print OUT "------------------------------------------------------------\n";
	print OUT "[INFO] $timestamp - DupHIST Step2. Synonymous substitution rate (Ks) estimation\n";
	print OUT "   - Task:        Calculated Ks based on internode relationships\n";
	print OUT "   - Input:       $temp_revise_nwk/*nwk\n";
	print OUT "   - Output:      $temp_revise_nwk/*pairks\n";  
	print OUT "   - Summary:     Total $output_count .pairks files generated successfully\n";
	print OUT "   - Status:      COMPLETED SUCCESSFULLY ✔\n";
	print OUT "   - Runtime:     $time_string\n";
	print OUT "------------------------------------------------------------\n";
	close (OUT);
	##################################

	$step = 3;
}

if ($step == 3)
{
	my $start_time = time();

	my @temp = glob ("$temp_revise_nwk/*nwk");
	my $total = scalar keys @temp;
	my $num = int ($total / $config->{Thread}{thread_num}) + 1;
	my $num_perl = $num * 3;

	## copy input data
	system ("cp $temp_revise_nwk/*pairks $temp_revise_nwk/*nodeinfo $temp_smooth");

	## index ks in node info
	system ("perl $script_path/bulk_index_ks_avg.pl $temp_smooth pairks $temp_smooth $script_path > $temp_sh/total_sm_avg.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_sm_avg.sh\" \"$temp_sh\/temp_sm_avg\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_sm_avg > $temp_sh/Run_sm_avg.sh");

	system ("sh $temp_sh/Run_sm_avg.sh >$temp_sh/Run_sm_avg.log 2>$temp_sh/Run_sm_avg.log2");        ## bulk
	
	system ("perl $script_path/validate_run_out.pl $temp_smooth pairks nodeinfo_ks >> duplication_validation.log");

	## build geneks 1st
	system ("perl $script_path/bulk_build_gene_ks_info.pl $temp_smooth nodeinfo_ks $temp_smooth $script_path > $temp_sh/total_sm_1gk.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_sm_1gk.sh\" \"$temp_sh\/temp_sm_1gk\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_sm_1gk > $temp_sh/Run_sm_1gk.sh");

	system ("sh $temp_sh/Run_sm_1gk.sh >$temp_sh/Run_sm_1gk.log 2>$temp_sh/Run_sm_1gk.log2");        ## bulk
	
	system ("perl $script_path/validate_run_out.pl $temp_smooth nodeinfo_ks geneks_1st >> duplication_validation.log");

	## smooth process (gene 1st -> geneks 4th)	
	system ("perl $script_path/bulk_smooth_process.pl $temp_smooth geneks_1st $temp_smooth $script_path > $temp_sh/total_smooth.sh");

	my $num_sm = $num_perl * 7;
	system ("split -d -l $num_sm --additional-suffix=.sh \"$temp_sh\/total_smooth.sh\" \"$temp_sh\/temp_smooth\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_smooth > $temp_sh/Run_smooth.sh");

	system ("sh $temp_sh/Run_smooth.sh >$temp_sh/Run_smooth.log 2>$temp_sh/Run_smooth.log2");        ## bulk
	
	system ("perl $script_path/validate_run_out.pl $temp_smooth geneks_1st geneks_4th >> duplication_validation.log");

	my @tmp = glob ("$temp_smooth/*geneks_4th");
	my $output_count = scalar keys @tmp;

	######### print log file #########
	my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);

	my $total_sec = time() - $start_time;
	my $hr  = int($total_sec / 3600);
	my $min = int(($total_sec % 3600) / 60);
	my $sec = $total_sec % 60;

	my $time_string = sprintf("%d hr %d min %d sec", $hr, $min, $sec);

	open (OUT, ">>duplication_progress.log");
	print OUT "------------------------------------------------------------\n";
	print OUT "[INFO] $timestamp - DupHIST Step3. Synonymous substitution rate (Ks) smoothing & refinement\n";
	print OUT "   - Task:        Resolved phylogenetic inconsistencies and smoothed Ks\n";
	print OUT "   - Input:       $temp_revise_nwk/*pairks\n";
	print OUT "   - Output:      $temp_smooth/*geneks_4th\n";  
	print OUT "   - Summary:     Total $output_count .geneks_4th files generated successfully\n";
	print OUT "   - Status:      COMPLETED SUCCESSFULLY ✔\n";
	print OUT "   - Runtime:     $time_string\n";
	print OUT "------------------------------------------------------------\n";
	close (OUT);
	##################################

	## build final file
	system ("perl $script_path/bulk_build_table.pl $temp_smooth geneks_4th $temp_smooth $script_path > $temp_sh/total_final.sh");

	system ("split -d -l $num_perl --additional-suffix=.sh \"$temp_sh\/total_final.sh\" \"$temp_sh\/temp_final\"");
	system ("perl $script_path/run_bulk.pl $temp_sh temp_final > $temp_sh/Run_final.sh");

	system ("sh $temp_sh/Run_final.sh >$temp_sh/Run_final.log 2>$temp_sh/Run_final.log2");        ## bulk
	
	system ("perl $script_path/validate_run_out.pl $temp_smooth geneks_4th table >> duplication_validation.log");

	## copy final files
	system ("mkdir -p $temp_path/../$config->{Result}{result_dendrogram_dir}");
	system ("cp $temp_revise_nwk/*nwk $temp_path/../$config->{Result}{result_dendrogram_dir}");
	
	my $header = "Species\tGroup\tNode\tPair1\tPair2\tKs";
	system("printf '$header\n' > $temp_path/../$config->{Result}{result_filename}");
	system ("cat $temp_smooth/*table >> $temp_path/../$config->{Result}{result_filename}");

	######### print log file #########
	my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);

	my $total_sec = time() - $total_start_time;
	my $hr  = int($total_sec / 3600);
	my $min = int(($total_sec % 3600) / 60);
	my $sec = $total_sec % 60;

	my $time_string = sprintf("%d hr %d min %d sec", $hr, $min, $sec);
	my $total_data = `wc -l < $temp_path/../$config->{Result}{result_filename}` - 1;

	open (OUT, ">>duplication_progress.log");
	print OUT "============================================================\n";
	#print OUT "------------------------------------------------------------\n";
	print OUT "[FINISH] $timestamp - DupHIST Pipeline All Steps Completed\n";
	print OUT "   - Summary:     Total $output_count prefix_group data analyzed successfully\n";	
	print OUT "   - Summary:     Total $total_data duplication events recorded\n";
	print OUT "   - Final Table: $config->{required_option}{output_dir}/$config->{Result}{result_filename}\n";
	print OUT "   - Final Tree:  $config->{required_option}{output_dir}/$config->{Result}{result_dendrogram_dir}\n";
	print OUT "   - Total Time:  $time_string\n";
	print OUT "   - Status:      ALL PROCESSES COMPLETED SUCCESSFULLY ✔\n";
	#print OUT "------------------------------------------------------------\n";
	print OUT "============================================================\n";
	close (OUT);
	##################################
	
	print "\n[DupHIST] Analysis is successfully finished.\n";
	print "[DupHIST] Final Table: $config->{required_option}{output_dir}/$config->{Result}{result_filename}\n";
	print "[DupHIST] Final Tree:  $config->{required_option}{output_dir}/$config->{Result}{result_dendrogram_dir}\n\n";
}
