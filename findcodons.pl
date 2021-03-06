#!/bin/sh
#! -*-perl-*-
eval 'exec perl -x -wS $0 ${1+"$@"}'
if 0;
# the previous line is for system that doesn’t support the magic #! line,
# or if the path to your interpreter is longer than 32 characters
# (a built-in limit on many systems), you may be able to work around.

#########
# Developed by Mattia Belli 2013-2018
#########
use warnings;
use strict;
#use diagnostics;


#3.1 Added RSCU calculation
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $prog_name = ($year + 1900).'-'.($mon+1).'-'.$mday;

my $input_file;

foreach (@ARGV) {
	$_ =~ s/[\r\n]//g;	#Remove \r \n from arguments
}

if ($ARGV[0]){
	$input_file = $ARGV[0];
} else {
	print "Please specify the name of a GeneBank FLAT file: ";
	$input_file = <STDIN>;
	chomp $input_file;
}

print "Specify the genes to be analyzed, if any (type ALL if you want to analyze all genes): ";
my $gene_to_analyze = <STDIN>;
chomp $gene_to_analyze;
$gene_to_analyze = undef unless $gene_to_analyze =~m/\w+/;

my $RSCU_switch = 0;

my $genes_filename if ($gene_to_analyze);
if ($gene_to_analyze and length $gene_to_analyze>25){
	$genes_filename = substr( $gene_to_analyze, 0, 25);
	$genes_filename .= "..and others";
} else {
	$genes_filename = $gene_to_analyze if ($gene_to_analyze);
}

open (DATA, "<", $input_file) or die "Cannot open $input_file .";
open (OUT, ">", "$input_file - [$prog_name] - CODONS.txt") or die "Cannot write the sequence file";
open (OUT1, ">", "$input_file - [$prog_name] - CODONS R Ready.txt") or die "Cannot write the sequence file";
open (OUT2, ">", "$input_file - [$prog_name] - CODONS RSCU.txt") or die "Cannot write the sequence file" if $RSCU_switch;
open (OUT3, ">", "$input_file - [$prog_name] - CODONW $genes_filename.txt") or die "Cannot write the sequence file" if $gene_to_analyze;
open (OUT4, ">", "$input_file - [$prog_name] - CODONW $genes_filename R Ready.txt") or die "Cannot write the sequence file" if $gene_to_analyze;
print OUT  "NAME	";
print OUT1  "NAME	";
print OUT2  "NAME	" if $RSCU_switch;
print OUT3  "NAME	" if $gene_to_analyze;
print OUT4  "NAME	" if $gene_to_analyze;
my $n;
my $accession_data;

my %codon2AA = (
	'GCA' => 'Ala',
	'GCC' => 'Ala',
	'GCG' => 'Ala',
	'GCT' => 'Ala',
	'AGA' => 'Arg',
	'AGG' => 'Arg',
	'CGA' => 'Arg',
	'CGC' => 'Arg',
	'CGG' => 'Arg',
	'CGT' => 'Arg',
	'AAC' => 'Asn',
	'AAT' => 'Asn',
	'GAC' => 'Asp',
	'GAT' => 'Asp',
	'TGC' => 'Cys',
	'TGT' => 'Cys',
	'CAA' => 'Gln',
	'CAG' => 'Gln',
	'GAA' => 'Glu',
	'GAG' => 'Glu',
	'GGA' => 'Gly',
	'GGC' => 'Gly',
	'GGG' => 'Gly',
	'GGT' => 'Gly',
	'CAC' => 'His',
	'CAT' => 'His',
	'ATA' => 'Ile',
	'ATC' => 'Ile',
	'ATT' => 'Ile',
	'CTA' => 'Leu',
	'CTC' => 'Leu',
	'CTG' => 'Leu',
	'CTT' => 'Leu',
	'TTA' => 'Leu',
	'TTG' => 'Leu',
	'AAA' => 'Lys',
	'AAG' => 'Lys',
	'ATG' => 'Met',
	'TTC' => 'Phe',
	'TTT' => 'Phe',
	'CCA' => 'Pro',
	'CCC' => 'Pro',
	'CCG' => 'Pro',
	'CCT' => 'Pro',
	'AGC' => 'Ser',
	'AGT' => 'Ser',
	'TCA' => 'Ser',
	'TCC' => 'Ser',
	'TCG' => 'Ser',
	'TCT' => 'Ser',
	'TAA' => 'STOP',
	'TAG' => 'STOP',
	'TGA' => 'STOP',
	'ACA' => 'Thr',
	'ACC' => 'Thr',
	'ACG' => 'Thr',
	'ACT' => 'Thr',
	'TGG' => 'Trp',
	'TAC' => 'Tyr',
	'TAT' => 'Tyr',
	'GTA' => 'Val',
	'GTC' => 'Val',
	'GTG' => 'Val',
	'GTT' => 'Val',
);
my %AA2codons = (			# Codons from NCBI The Bacterial, Archaeal and Plant Plastid Code (transl_table=11)
   'Ala' => [qw/GCA GCC GCG GCT/],
   'Gly' => [qw/GGA GGC GGG GGT/],
   'Pro' => [qw/CCA CCC CCG CCT/],
   'Thr' => [qw/ACA ACC ACG ACT/],
   'Val' => [qw/GTA GTC GTG GTT/],
   
   'Ser' => [qw/AGC AGT TCA TCC TCG TCT/],
   'Arg' => [qw/AGA AGG CGA CGC CGG CGT/],
   'Leu' => [qw/CTA CTC CTG CTT TTA TTG/],
   
   'Phe' => [qw/TTC TTT/],
   
   'Asn' => [qw/AAC AAT/],
   'Lys' => [qw/AAA AAG/],
   
   'Asp' => [qw/GAC GAT/],
   'Glu' => [qw/GAA GAG/],
   
   'His' => [qw/CAC CAT/],
   'Gln' => [qw/CAA CAG/],
   
   'Tyr' => [qw/TAC TAT/],
   'STOP' => [qw/TAA TAG TGA/],
   
   'Ile' => [qw/ATA ATC ATT/],
   'Met' => [qw/ATG/],
   
   'Cys' => [qw/TGC TGT/],
   'Trp' => [qw/TGG/],
   # 'SelCys' => [qw/TCA/]
);
# my %AA_isoacceptor_types = (	
   # 'Ala' ,4,
   # 'Gly' ,4,
   # 'Pro' ,4,
   # 'Thr' ,4,
   # 'Val' ,4,
   
   # 'Ser' ,6,
   # 'Arg' ,6,
   # 'Leu' ,6,
   
   # 'Phe' ,2,
   
   # 'Asn' ,2,
   # 'Lys' ,2,
   
   # 'Asp' ,2,
   # 'Glu' ,2,
   
   # 'His' ,2,
   # 'Gln' ,2,
   
   # 'Tyr' ,2,
   # 'STOP' ,3,
   
   # 'Ile' ,3,
   # 'Met' ,1,
   
   # 'Cys' ,2,
   # 'Trp' ,1,
   # 'SelCys' ,1,
# );

foreach (sort keys %AA2codons){
	my $AA = $_;
	my $ref = $AA2codons{$_};
	foreach (sort @$ref){	
		print OUT "$_ $AA	";
		print OUT1 "$_ $AA	";
		print OUT2 "$_ $AA	" if $RSCU_switch;
		print OUT3 "$_ $AA	" if $gene_to_analyze;
		print OUT4 "$_ $AA	" if $gene_to_analyze;
	}
}

print OUT "\n";
print OUT1 "\n";
print OUT2 "\n" if $RSCU_switch;
print OUT3 "\n" if $gene_to_analyze;
print OUT4 "\n" if $gene_to_analyze;


chdir "CodonW" or die "Cannot find CodonW";

while (<DATA>) {	
	$accession_data .= $_; 
	next unless ($_ =~ m|^\/\/|);	#One record at a time
	++$n;
	
	my ($name, $organism, $date, $id, $sequence) = '' x 5;
	if ($accession_data =~ m|VERSION\s+(.+?)\s|g){
		$id = $1;
	} 	
	
	# if ($accession_data =~ m|DEFINITION\s+(.+),|){
		# $name = $1;
	# }
	if ($accession_data =~ m|ORGANISM\s+(.+?)\n(.+?)\.\n|sg){
		$name = $1;
		# $organism = $2;
	}
	
	# $organism =~ s/^[\s]+//g;
	# $organism =~ s/\s{2,}/ /g;
	
	$name .= " $id"; 
	
	
	print "Processing ($n)..$name ";
	
	#Skips if there are not CDS annotations
	unless ($accession_data =~ m!\n\s{5,}(CDS\s{5,}.+?)\/translation!sg) {
		print "$name -> no CDSs found!\n";
		undef $accession_data;
		next;
	}
	
	if ($accession_data =~ m/ORIGIN([\W\w]+)\n\/\//){
		$sequence = $1; 
		$sequence =~ s/[\W\d]+//g;
	} else {
		print "$name -> no SEQUENCE found!\n";
		next;
	}
	
	
	open (all_CDS_seq, ">", "all_CDS_SEQ.txt") or die "Cannot write the sequence file";
	if ($gene_to_analyze) {
		open (gene_CDS_seq, ">", "gene_CDS_SEQ.txt") or die "Cannot write the sequence file";	
	}
	
	my @name_list = ();
	my ($n_cds, $found_gene, $gene_found) = '' x 3;
	while ($accession_data =~ m!\n\s{5,}(CDS\s{5,}.+?)\/translation!sg){
		++$n_cds;
		my $cds = $1;
		my ($seq_position, $annotation, $CDS_seq) = '' x 3;
		my $gene_name = 'Unknown';
		$gene_name = $1 if ($cds =~ m|\/db_xref="(.+)"|);
		$gene_name = $1 if ($cds =~ m|\/locus_tag="(.+)"|);
		$gene_name = $1 if ($cds =~ m|\/protein_id="(.+)"|);
		$gene_name = $1 if ($cds =~ m|\/gene="(.+)"|);
		$gene_name = lcfirst $gene_name;
	
		if ($cds =~ m|(CDS\s+(?:complement\()?join\((.+?)\))\n|s){
			$annotation = $1;
			$seq_position = $2;
			$seq_position =~ s/\n\s+//g;
			$annotation =~ s/\n\s+//g;
			my @parts = split (",", $seq_position);
			foreach (@parts){
				my ($start, $end) = '';
				if ($_ =~ m|complement\((\d+)\.\.(\d+)\)|){
					$start = $1;
					$end = $2;
					my $part_seq = substr ($sequence, $start-1, $end-$start+1);
					$CDS_seq .= &reverse_complement($part_seq);
				} elsif ($_ =~ m|^(\d+)\$|) {
					$CDS_seq .= substr ($sequence, $1, 1);
				} elsif ($_ =~ m|(\d+)\.\.(\d+)|){
					$start = $1;
					$end = $2;
					my $part_seq = substr ($sequence, $start-1, $end-$start+1);
					$CDS_seq .= $part_seq;
				}		
			}	
		} elsif ($cds =~ m|(CDS.+?>?(\d+)\.\.>?(\d+))|){
			$annotation = $1;
			my $start = $2;
			my $end = $3;
			$seq_position = "$start..$end";
			$CDS_seq = substr ($sequence, $start-1, $end-$start+1);
		}
		if ($cds =~ m|CDS\s+complement|) {
			$CDS_seq = &reverse_complement($CDS_seq);		
		}
		$annotation =~ s/\s{2,}/ /g;
		
		print all_CDS_seq ">$name $gene_name $annotation\n$CDS_seq\n\n";

		my $regex = $gene_to_analyze if $gene_to_analyze;
		$regex =~ s/\s+?/\|/g if $gene_to_analyze;
		
		if ($gene_to_analyze and (uc $gene_to_analyze eq 'ALL')){
			++$found_gene;
			push (@name_list, "$name [$gene_name]");
			print gene_CDS_seq ">$name $gene_name $annotation\n$CDS_seq\n\n";
		} elsif ($gene_to_analyze and $gene_name =~ m|^($regex)$|i){
			++$found_gene;
			push (@name_list, "$name [$gene_name]");
			print gene_CDS_seq ">$name $gene_name $annotation\n$CDS_seq\n\n";
		}
		# print ">$gene_name $annotation\n$CDS_seq\n\n";
		# <>;
	}
	print "$n_cds CDSs FOUND\n";
	close all_CDS_seq;
	close gene_CDS_seq if ($gene_to_analyze);	

	
	system ('./codonw all_CDS_SEQ.txt -nomenu -silent -total >/dev/null 2>&1');

	open (CODONW, "<", 'all_CDS_SEQ.blk') or die "Cannot open CodonW output file";
	my $codonW = '';
	$codonW = join ("",<CODONW>);
	close CODONW;
	
	# system ('mv all_CDS_SEQ.blk last_all_CDS_SEQ.blk');
	# system ('mv all_CDS_SEQ.out last_all_CDS_SEQ.out');
	# system ('mv all_CDS_SEQ.txt last_all_CDS_SEQ.txt');
	
	# my %tot_codon_per_AA;
	my %codon_table;
	my %codon_table_rscu;
	# print $codonW;
	while ($codonW =~ m!([AUCG]+)(?:\s+)?(\d+)\s*([\d\.]+)!g){
		my ($triplet, $codon_number, $rscu) = ($1, $2, $3);
		# print "\n$triplet";
		$triplet =~ s/U/T/g;
		# print "\n$triplet";
		# print "\n$codon2AA{$triplet}";
		$codon_table{$triplet} = $codon_number;
		$codon_table_rscu{$triplet} = $rscu;
		# print "\n$codon_table{$triplet}";
		# $tot_codon_per_AA{$codon2AA{$triplet}} += $codon_number;
		# print "\n$tot_codon_per_AA{$codon2AA{$triplet}}";
	}
	print OUT "$name	";
	print OUT1 "$name	";
	print OUT2 "$name	" if $RSCU_switch;
	
	foreach my $AA (sort keys %AA2codons){
		my $ref = $AA2codons{$AA};
		foreach (sort @$ref){		#Sorting method has to be revised
			my $triplet = $_;
			# my $rscu_score;
			# if ($tot_codon_per_AA{$AA} == 0) {
				# $rscu_score = 0;
			# } else {
				# $rscu_score = ($codon_table{$triplet}/$tot_codon_per_AA{$AA})*(scalar @$ref);
			# }
			print OUT "$triplet $codon_table{$triplet}	";
			print OUT1 "$codon_table{$triplet}	";
			print OUT2 "$triplet $codon_table_rscu{$triplet}	" if $RSCU_switch;
			# print "$triplet $codon_table_rscu{$triplet}	";
			# print "\n\n$AA";
			# print "\n$triplet";
			# print "\n$codon_table{$triplet}";
			# print "\n$tot_codon_per_AA{$AA}";		
			# print "\n ", scalar @$ref;
			# print "\n$rscu_score";	
			# <>;
		}
	}	

	undef %codon_table;
	undef %codon_table_rscu;
	print OUT "\n";
	print OUT1 "\n";
	
	print OUT2 "\n" if $RSCU_switch;
	
	
	if ($found_gene) {
		system ('CodonW.exe gene_CDS_SEQ.txt -nomenu -silent >NUL 2>&1');
		open (CODONW2, 'gene_CDS_SEQ.blk') or die "Cannot open CodonW output file";
		
		my $CUD_number = '';
		my $codonW_data = '';
		while (<CODONW2>) {	
			$codonW_data .= $_; 
			next unless ($_ =~ m|Genetic code|);	#Loads input data and processes them one by one
			++$CUD_number;
			my %codon_table_all;
			while ($codonW_data =~ m!([AUCG]+)(?:\s+)?(\d+)\s*([\d\.]+)!g){
				my $triplet = $1;
				my $codon_number = $2;
				$triplet =~ s/U/T/g;
				$codon_table_all{$triplet} = $codon_number;
			}
			print OUT3 $name_list[$CUD_number-1]."	";
			print OUT4 $name_list[$CUD_number-1]."	";
			
			foreach my $AA (sort keys %AA2codons){
				my $ref = $AA2codons{$AA};
				foreach (sort @$ref){		#Sorting method has to be revised
				my $triplet = $_;
				print OUT3 "$triplet $codon_table_all{$triplet}	";
				print OUT4 "$codon_table_all{$triplet}	";
				}
			}
			# foreach (sort keys %codon_table_all){
				# print OUT3 "$_ $codon_table_all{$_}	";
			# }

			print OUT3 "\n";
			print OUT4 "\n";
			undef $codonW_data;
		}
		close CODONW2;
	}
	undef $accession_data;
}


chdir;


close DATA;
close OUT;
close OUT1;
close OUT2 if $RSCU_switch;
close OUT3 if $gene_to_analyze;
close OUT4 if $gene_to_analyze;

sub reverse_complement {
        my $dna = shift;
	# reverse the DNA sequence
        my $revcomp = reverse($dna);

	# complement the reversed DNA sequence
        $revcomp =~ tr/ACGTacgt/TGCAtgca/;
        return $revcomp;
}

print "\n\n****DONE****\n\n";

exit;