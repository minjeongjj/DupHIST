use strict;

use Config::Tiny;
use Data::Dumper qw(Dumper);
use Cwd 'abs_path';
use List::Util qw/ min max /;

my $filename = shift or die "Usage: $0 FILENAME\n";
my $config = Config::Tiny->read( $filename, 'utf8' );

my @current_script = split /\//, $0;
pop @current_script;
my $script_path = join "/", @current_script;

my $temp_path = "$config->{required_option}{Output_directory}/$config->{Result}{temp_path}";
my $temp_sh = "$temp_path/temp_sh";
#$config->{Temp_folders}{bash_path}";
my $temp_cds = "$temp_path/CDS_for_alignment";
#$config->{Temp_folders}{cds_path}";
my $temp_best = "$temp_path/best.fas";
#$config->{Temp_folders}{alignment_result_path}";
my $temp_axt = "$temp_path/axt";
#$config->{Temp_folders}{axt_path}";
my $temp_kaks = "$temp_path/Ks_value";
#$config->{Temp_folders}{ks_value_path}";
my $temp_mat = "$temp_path/matrices";
#$config->{Temp_folders}{matrix_path}";
my $groupinfo_path = "$temp_path/groupinfo";
#$config->{Temp_folders}{groupinfo_path}";
my $hcluster_path = "$temp_path/hcluster";
#$config->{Temp_folders}{Hcluster_path}";
#print "$config->{program_path}{PRANK}\n";

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
		if($stLine =~ /CDS file Done/ || $stLine =~ /Error 1/)
		{
			$step = 2;
		}
		elsif($stLine =~ /Alignment & Ks value calculation Done/ || $stLine =~ /Error 2/)
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

#$step = 4;

system("rm -rf duplication_progress.log");

system("mkdir -p $config->{required_option}{Output_directory}");
system("mkdir -p $temp_path");
system("mkdir -p $temp_sh");
system("mkdir -p $temp_cds");
system("mkdir -p $temp_best");
system("mkdir -p $temp_axt");
system("mkdir -p $temp_kaks");
system("mkdir -p $temp_mat");
system("mkdir -p $groupinfo_path");
system("mkdir -p $hcluster_path");

my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
$year += 1900;
$mon += 1;
my $gi_sum = 0;
if ($step == 1)
{
	open(LOG, ">duplication_progress.log");
	print LOG "\n\n$year-$mon-$mday    Duplication time calculation Start..\n\n\n\n";
	close(LOG);
	system("python3 $script_path/1.split_groupinfo.py $filename");
	
	#my $gi_sum = 0;
	my %gi_hash = ();
	
	open(GROUP, "$temp_path/group_info.stat");
	while(my $stLine = <GROUP>)
	{
		chomp $stLine;
		my @stInfo = split /\s/, $stLine;
		$gi_sum += $stInfo[1];
		$gi_hash{$stInfo[0]} = $stInfo[1];
	}
	
	my $lim = $gi_sum / $config->{Thread}{thread_num};
	my $temp_sum = 0;
	my $gi_idx = 0;
	
	my @temp_cds = glob("$temp_sh/temp_cds*.sh");
	for(my $i = 0 ; $i <= $#temp_cds; $i++)
	{
		system("rm -rf $temp_cds[$i]");
	}

	foreach my $key (keys %gi_hash)
	{
		if ($gi_hash{$key} + $temp_sum > $lim)
		{
			open(TMP, ">>$temp_sh/temp_cds$gi_idx.sh");
			print TMP "perl $script_path/prepare_CDS.pl $groupinfo_path/$key.txt $config->{required_option}{CDS_path} $temp_cds\n";
			print TMP "wait;\n";
			$gi_idx++;
			$temp_sum = 0;
			close(TMP);
		}
		else
		{
			open(TMP, ">>$temp_sh/temp_cds$gi_idx.sh");
	                print TMP "perl $script_path/prepare_CDS.pl $groupinfo_path/$key.txt $config->{required_option}{CDS_path} $temp_cds\n";
			$temp_sum += $gi_hash{$key};
			print TMP "wait;\n";
			close(TMP);
		}
		
	}
	open(CDS, ">$temp_sh/Run_cds.sh");
	my @temp_cds_sh = glob("$temp_sh/temp_cds*.sh");
	for(my $i = 0; $i <= $#temp_cds_sh ; $i++)
	{
		print CDS "sh $temp_sh/temp_cds$i.sh &\n";
	}
	print CDS "wait;\n";
	close(CDS);
	
	system("sh $temp_sh/Run_cds.sh");
}

my $group_cnt = 0;
if($step <=2)
{
	system("perl $script_path/Count_files.pl $temp_cds > number_of_pairs");
	open(CNT, "number_of_pairs");
	system("rm -rf number_of_pairs");
	while(my $stLine = <CNT>)
	{
		chomp $stLine;
		$group_cnt = $stLine;
	}
	open(LOG, ">>duplication_progress.log");
        
	if ($gi_sum == $group_cnt)
	{
		print LOG "$group_cnt paris CDS file Done\n\n";
	}
	elsif($group_cnt == 0)
	{
		print LOG "All CDS files may not have been created. You should check it out.\n";
                print LOG "Error 1\n";
                exit();
	}
	else
	{
		print LOG "All CDS files may not have been created. You should check it out.\n";
		print LOG "Error 1\n";
		exit();
	}
	close(LOG);
	my @group_info = glob("$groupinfo_path/*");
	my $max_line = $group_cnt / $config->{Thread}{thread_num};
	
	my @temp_pipeline = glob("$temp_sh/temp_pipeline*.sh");
	for(my $i = 0 ; $i <= $#temp_pipeline; $i++)
	{
	        system("rm -rf $temp_pipeline[$i]");
	}
	
	my $idx = 0;
	my $i = 0;

	open(LOG, ">>duplication_progress.log");
	print LOG "Alignment & Ks value Calculation Start\n\n";
	print LOG "-----------Your option\n";
	print LOG "Alignment Iteration Option : $config->{PRANK_option}{iteration}\n";
	print LOG "Ks value calculation Option - genetic code : $config->{kaks_cal_option}{genetic_code}\n";
	print LOG "Ks value calculation Option - method : $config->{kaks_cal_option}{method}\n";
	print LOG "H-cluster Option - all/each : $config->{statistical_option}{Hcluster_method}\n";
	print LOG "Thread : $config->{Thread}{thread_num}\n";
	print LOG "-----------------------------\n\n";

	close(LOG);
	my $line_num=0;	
	my @cds_files = glob("$temp_cds/*");
	for(my $i; $i<=$#cds_files; $i++)
	{
		open(SH, ">>$temp_sh/temp_pipeline$idx.sh");
		$cds_files[$i] =~ s/$temp_cds\///g;
		$cds_files[$i] =~ s/.CDS.fasta//g;
		if ($line_num < $max_line)
		{
			print SH "perl $script_path/prank_to_ks_for_pair.pl $cds_files[$i] $config->{program_path}{PRANK} $config->{PRANK_option}{iteration} $config->{PRANK_option}{sleep_time} $config->{program_path}{kaks} $config->{kaks_cal_option}{method} $config->{kaks_cal_option}{genetic_code} $temp_cds $temp_best $temp_axt $temp_kaks $script_path\n";
			print SH "wait;\n";
			close(SH);
		}
		else
		{
			$line_num = 0;
			$idx += 1;
			open(SH, ">>$temp_sh/temp_pipeline$idx.sh");
			print SH "perl $script_path/prank_to_ks_for_pair.pl $cds_files[$i] $config->{program_path}{PRANK} $config->{PRANK_option}{iteration} $config->{PRANK_option}{sleep_time} $config->{program_path}{kaks} $config->{kaks_cal_option}{method} $config->{kaks_cal_option}{genetic_code} $temp_cds $temp_best $temp_axt $temp_kaks $script_path\n";
	                print SH "wait;\n";
			close(SH);
		}
		$line_num++;
	}
	
	open(SH,">$temp_sh/Run_pipeline.sh");
	for(my $i = 0; $i<=$config->{Thread}{thread_num}; $i++)
	{
		print SH "sh $temp_sh/temp_pipeline$i.sh &\n";
	}
	print SH "wait;\n";
	close(SH);
	
	system("sh $temp_sh/Run_pipeline.sh");
	
	my @tmpdir = glob("tmpdirprank*");
	for(my $i=0; $i <=$#tmpdir; $i++)
	{
		system("rm -rf $tmpdir[$i]");
	}

	my @ks_files = glob("$temp_kaks/*.kaks");
	open(LOG, ">>duplication_progress.log");
	if ($#ks_files == $#cds_files)
	{
		print LOG "Alignment & Ks value calculation Done ($group_cnt)\n";
	}
	else
	{
		print LOG "All CDS pairs may not have been analysis. You should check it out.\n";
                print LOG "Error 2\n";
                exit();
	}
	close(LOG);
}

if($step <= 3)
{
	open(LOG, ">>duplication_progress.log");
        print LOG "\nMatrix file start...\n";
        close(LOG);

	system("perl $script_path/ks_to_matrix.pl $temp_kaks $temp_kaks $temp_mat $script_path $groupinfo_path");
	
	open(LOG, ">>duplication_progress.log");
        print LOG "\nMatrix file Done\n";
        close(LOG);
}

my $r_input_path = abs_path($temp_mat);
my $real_each;
my $all_method;
my @tmp_list;
if($step <=4)
{
	open(LOG, ">>duplication_progress.log");
        print LOG "H-clustering Start...\n";
        close(LOG);
	
	system("Rscript $script_path/hclustering_changeName.R $r_input_path/ $hcluster_path/ $config->{statistical_option}{Hcluster_method}");
 
	my $cophenetic_path = "$hcluster_path/Cophenetic_value/";
	system("mkdir -p $cophenetic_path");

	my $each_path = "$hcluster_path/Result_optimal_each";
	
	system("Rscript $script_path/get_ccc.R $hcluster_path $cophenetic_path");

	my $method_values = $config->{statistical_option}{preferred_method_order};
        $method_values =~ s/\[//g;
        $method_values =~ s/\]//g;
        my @method_value_list = split/,/, $method_values;
	my $fir_met = $method_value_list[0];
	if ($config->{statistical_option}{Hcluster_method} eq "each")
	{
		$real_each = "$hcluster_path/Result_optimal_each_real";
		system("mkdir -p $real_each");
		system("python3 $script_path/optimal_method_each.py $hcluster_path $filename");	
		#		my @cophenetics = glob("$hcluster_path/Cophenetic_value/*_cophenetic.txt");
		#		for (my $i = 0; $i < $#cophenetics; $i++)
		#		{
		#			open(CO, $cophenetics[$i]);
		#			while(my $stLine = <CO>)
		#			{
		#				chomp $stLine;
		#				if ($stLine =~ /single/)
		#				{
		#					next;
		#				}
		#				my @stInfo = split /\s/, $stLine;
		#				my $prefix = $stInfo[0];
		#				$prefix =~ s/\"//g;
		#				$prefix =~ s/\.matrix//g;
		#				my $spe = $prefix;
		#				$spe =~ s/\_.*//g;
		#				system("mkdir -p $real_each/$spe");
		#				shift @stInfo;
		#				my $MaxCCC = max(@stInfo);
		#				my @a = ();
		#				my $tmp = 0;
		#				my $best_method;
		#				for(my $i = 0; $i <=5; $i++)
		#				{
		#					if ($stInfo[$i] == $MaxCCC)
		#					{
		#						$a[$tmp++] = ($i+1);
		#						print "$tmp\n";
		#					}
		#				}
		#				#print "$MaxCCC\n";
		#				#print "$#a\n";
		#				for(my $i = 0; $i <5; $i++)
		#                                {
		#					for(my $j = 0; $j<$#a; $j++)
		#					{
		#						if($method_value_list[$i] == $a[$j])
		#						{
		#							$best_method = $method_value_list[$i];
		#							last;
		#						}
		#					}
		#					if($best_method >0)
		#					{
		#						last;
		#					}
		#				}
		#				system("cp $hcluster_path/Result_M$best_method/$spe/$prefix.* $real_each/$spe");
		#			}
		#}

		system("perl $script_path/getDuplicationHistory.pl $real_each");
		system("perl $script_path/getKAKSRatio_Avrg_mute.pl each $real_each");
		system("perl $script_path/1.Combine_KS_muteKA_Avrg.pl $real_each/ $config->{required_option}{Output_directory}/$config->{Result}{result_filename}");
		print("perl $script_path/1.Combine_KS_muteKA_Avrg.pl $real_each/ $config->{required_option}{Output_directory}/$config->{Result}{result_filename}");
	}

	elsif($config->{statistical_option}{Hcluster_method} eq "all")
	{
		system("python $script_path/optimal_method.py $hcluster_path $filename > $hcluster_path/all_method");
		open(OP,"$hcluster_path/all_method");
		my $all_method;
		while(my $stLine = <OP>)
		{
			chomp $stLine;
			$all_method = $stLine;
		}
	
		system("perl $script_path/getDuplicationHistory.pl $hcluster_path/Result_M$all_method");
	        system("perl $script_path/getKAKSRatio_Avrg_mute.pl $all_method $hcluster_path/Result_M$all_method");
	        system("perl $script_path/1.Combine_KS_muteKA_Avrg.pl $hcluster_path/Result_M$all_method $config->{required_option}{Output_directory}/$config->{Result}{result_filename}");
	}	
	open(LOG, ">>duplication_progress.log");
        print LOG "H-clustering Done\n\n";
	print LOG "Duplication time calculation Done\n";
        close(LOG);
}
