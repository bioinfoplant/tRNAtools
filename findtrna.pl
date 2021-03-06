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
use List::Util qw(first);
use warnings;
use strict;
# use LWP;
use Benchmark;
#use diagnostics;
use IO::Tee;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $prog_name = ($year + 1900).'-'.($mon+1).'-'.$mday;

my $os = $^O;
print "Running in: $os\n";
unless ($os =~ /(linux|cygwin)/){
	print "You need a unix-based OS or emulation (cygwin) to run this script";
	<>;
	exit;
}

$ENV{PATH}.=':/home/tRNAscan2/bin';
$ENV{PERL5LIB}.=':/home/tRNAscan2/lib';
$ENV{MANPATH}.=':/home/tRNAscan2/share/man';


my $input_file;

foreach (@ARGV) {
	$_ =~ s/[\r\n]//g;	#Remove \r \n from arguments
}

if ($ARGV[0]){
	$input_file = $ARGV[0];
} else {
	print "Please specify the name of the GeneBank FLAT file: ";
	$input_file = <STDIN>;
	chomp $input_file;
}

#I/O

my $out2 = 0;
my $out5 = 0;
my $out6 = 0;

open (DATA, "<", $input_file) or die "Cannot read the data file";
open (OUT, ">", "$input_file - [$prog_name] tRNA FULL Data.txt") or die "Cannot write the output files";
open (OUT2, ">", "$input_file - [$prog_name] tRNA ANTICODONS Data.txt") or die "Cannot write the output files" if $out2;
open (OUT3, ">", "$input_file - [$prog_name] tRNA Data.txt") or die "Cannot write the output files";
open (OUT4, ">", "$input_file - [$prog_name] tRNA R READY.txt") or die "Cannot write the output files";
open (OUT5, ">", "$input_file - [$prog_name] tRNA R READY RGF.txt") or die "Cannot write the output files" if $out5;
open (OUT6, ">", "$input_file - [$prog_name] tRNA R READY RGF x size correction.txt") or die "Cannot write the output files" if $out6;
open (OUT7, ">", "$input_file - [$prog_name] tRNA Discarded species.txt") or die "Cannot write the output files";
open (OUT8, ">", "$input_file - [$prog_name] tRNA Warnings.txt") or die "Cannot write the output files";
open (LOG, ">", "$input_file - [$prog_name] LOG.txt") or die "Cannot write the log file";

my $tee = IO::Tee->new(\*STDOUT, \*LOG);
select $tee;

my @tRNA = qw(Phe Leu Ile Met Val Ser Pro Thr Ala Tyr His Gln Asn Lys Asp Glu Cys Trp Arg Gly);

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
   # 'STOP' => [qw/TAA TAG TGA/],
   
   'Ile' => [qw/ATA ATC ATT/],
   'Met' => [qw/ATG/],
   
   'Cys' => [qw/TGC TGT/],
   'Trp' => [qw/TGG/],
   # 'SelCys' => [qw/TGA/]
);

my %AA2anticodons = (			# Anticodons, rev complement of NCBI The Bacterial, Archaeal and Plant Plastid Code (transl_table=11)
   'Ala' => [qw/AGC GGC CGC TGC/],
   'Gly' => [qw/ACC GCC CCC TCC/],
   'Pro' => [qw/AGG GGG CGG TGG/],
   'Thr' => [qw/AGT GGT CGT TGT/],
   'Val' => [qw/AAC GAC CAC TAC/],
   
   'Ser' => [qw/AGA GGA CGA TGA ACT GCT/],
   'Arg' => [qw/ACG GCG CCG TCG CCT TCT/],
   'Leu' => [qw/AAG GAG CAG TAG CAA TAA/],
   
   'Phe' => [qw/AAA GAA/],
   
   'Asn' => [qw/ATT GTT/],
   'Lys' => [qw/CTT TTT/],
   
   'Asp' => [qw/ATC GTC/],
   'Glu' => [qw/CTC TTC/],
   
   'His' => [qw/ATG GTG/],
   'Gln' => [qw/CTG TTG/],
   
   'Tyr' => [qw/ATA GTA/],
   # 'STOP' => [qw/CTA TTA TCA/],
   
   'Ile' => [qw/AAT GAT  TAT/],
   'Met' => [qw/CAT/],
   
   'Cys' => [qw/ACA GCA/],
   'Trp' => [qw/CCA/],
   # 'SelCys' => [qw/TCA/]
);

my %AA_isoacceptor_types = (	
   'Ala' ,4,
   'Gly' ,4,
   'Pro' ,4,
   'Thr' ,4,
   'Val' ,4,
   
   'Ser' ,6,
   'Arg' ,6,
   'Leu' ,6,
   
   'Phe' ,2,
   
   'Asn' ,2,
   'Lys' ,2,
   
   'Asp' ,2,
   'Glu' ,2,
   
   'His' ,2,
   'Gln' ,2,
   
   'Tyr' ,2,
   # 'STOP' ,3,
   
   'Ile' ,3,
   'Met' ,1,
   
   'Cys' ,2,
   'Trp' ,1,
   # 'SelCys' ,1,
);


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


my %anticodon2AA = (
	'AGC' => 'Ala',
	'GGC' => 'Ala',
	'CGC' => 'Ala',
	'TGC' => 'Ala',
	'ACC' => 'Gly',
	'GCC' => 'Gly',
	'CCC' => 'Gly',
	'TCC' => 'Gly',
	'AGG' => 'Pro',
	'GGG' => 'Pro',
	'CGG' => 'Pro',
	'TGG' => 'Pro',
	'AGT' => 'Thr',
	'GGT' => 'Thr',
	'CGT' => 'Thr',
	'TGT' => 'Thr',
	'AAC' => 'Val',
	'GAC' => 'Val',
	'CAC' => 'Val',
	'TAC' => 'Val',
	'AGA' => 'Ser',
	'GGA' => 'Ser',
	'CGA' => 'Ser',
	'TGA' => 'Ser',
	'ACT' => 'Ser',
	'GCT' => 'Ser',
	'ACG' => 'Arg',
	'GCG' => 'Arg',
	'CCG' => 'Arg',
	'TCG' => 'Arg',
	'CCT' => 'Arg',
	'TCT' => 'Arg',
	'AAG' => 'Leu',
	'GAG' => 'Leu',
	'CAG' => 'Leu',
	'TAG' => 'Leu',
	'CAA' => 'Leu',
	'TAA' => 'Leu',
	'AAA' => 'Phe',
	'GAA' => 'Phe',
	'ATT' => 'Asn',
	'GTT' => 'Asn',
	'CTT' => 'Lys',
	'TTT' => 'Lys',
	'ATC' => 'Asp',
	'GTC' => 'Asp',
	'CTC' => 'Glu',
	'TTC' => 'Glu',
	'ATG' => 'His',
	'GTG' => 'His',
	'CTG' => 'Gln',
	'TTG' => 'Gln',
	'ATA' => 'Tyr',
	'GTA' => 'Tyr',
	'AAT' => 'Ile',
	'GAT' => 'Ile',
	'TAT' => 'Ile',
	'CAT' => 'Met',
	'ACA' => 'Cys',
	'GCA' => 'Cys',
	'CCA' => 'Trp'
);

my %one_letter2three_letter = (
	'A' => 'Ala',
	'G' => 'Gly',
	'P' => 'Pro',
	'T' => 'Thr',
	'V' => 'Val',
	'S' => 'Ser',
	'R' => 'Arg',
	'L' => 'Leu',
	'F' => 'Phe',
	'N' => 'Asn',
	'K' => 'Lys',
	'D' => 'Asp',
	'E' => 'Glu',
	'H' => 'His',
	'Q' => 'Gln',
	'Y' => 'Tyr',
	'I' => 'Ile',
	'M' => 'Met',
	'C' => 'Cys',
	'W' => 'Trp'
);

print OUT  "NAME	DEFINITION	DIVISION	SIZE	NCBI ID	CLASSIFICATION	DATE	TOTAL tRNAs	tRNA species	tRNAs standard	Unknown Anticodons	";
print OUT2  "NAME	DIVISION	SIZE	NCBI ID	CLASSIFICATION	DATE	TOTAL STANDARD ANTICODONS	" if $out2;
print OUT3  "NAME	DIVISION	SIZE	CLASSIFICATION	TOTAL STANDARD CODONS	tRNA species	";
print OUT4  "NAME	DIVISION	";
print OUT5  "NAME	DIVISION	" if $out5;
print OUT6  "NAME	DIVISION	" if $out6;
print OUT8  "NAME	STATS	Pseudo tRNA	fMet	Non-standard tRNA	MISSMATCH Gene and Product	MISSMATCH Codon and anticodon	tRNA-CAU annotated as tRNA-Ile	tRNAscan-SE Pseudogene	MISSMATCH Ile/Met from tRNAscan-SE	MISMATCH tRNAscan Amino Acid vs Annotated AA";


foreach (0..$#tRNA) {
	print OUT "$tRNA[$_]	";
}

foreach (sort keys %AA2anticodons){
	my $AA = $_;
	my $ref = $AA2anticodons{$_};
	foreach (sort @$ref){	
		my $anticodon = $_;
		my $codon = &reverse_complement($_);
		print OUT2 "trn-$AA ANTICODON: $anticodon CODON: $codon	" if $out2;
	}
}

foreach (sort keys %AA2codons){
	my $AA = $_;
	my $ref = $AA2codons{$_};
	foreach (sort @$ref){	
		my $codon = $_;
		print OUT3 "$codon $AA 	";
		print OUT4 "$codon $AA 	";
		print OUT5 "$codon $AA 	" if $out5;
		print OUT6 "$codon $AA 	" if $out6;
	}
}

print OUT "\n";
print OUT2 "\n" if $out2;
print OUT3 "\n";
print OUT4 "\n";
print OUT5 "\n" if $out5;
print OUT6 "\n" if $out6;


my $n;
my $accession_data;
my %results;
my %results2;
my %results3;
my %results4;
my %results5;
my %results6;
my %ids;
my %names;
my %chromosomes;
my %results_warning;

my $start_time = new Benchmark;


###################################################
######## SCAN every accessions, one by one ########

while (<DATA>) {	
	$accession_data .= $_; 
	next unless ($_ =~ m|^\/\/|);	#Loads one record at once.
	++$n;
	
	print "\n*Processing.. $n \n";
	
	
	my ($name, $source, $definition, $organism, $date, $size, $id, $sequence, $id_gi) = '' x 9;
	if ($accession_data =~ m|LOCUS.+\s+?(\d+)\s?bp.+?(\S+)\n|){
		$date = lc ($2);
		$size = $1;
	} else {
		$date = 'ND';
	}

	if ($accession_data =~ m|DEFINITION\s+?(.+(?:\s.+)\.)|){
		$definition = $1;
		$definition =~ s/\s+/ /g;
	} else {
		$definition = 'ND';
	}
	
	
	if ($accession_data =~ m|SOURCE\s+(.+)\n|){
		$source = $1;
	}
	
	if ($accession_data =~ m|VERSION\s+(.+?)(?:\s+GI:(.+?))?\n|){
		$id = $1;
		$id_gi = $2;
	}
	
	if ($accession_data =~ m|ORGANISM\s+(.+?)\n(.+?)\.\n|s){
		$name = $1;
		$organism = $2;
	}
	
	
	if ($id_gi)	{$ids{$id_gi} = $name} else {$ids{$id} = $name}
	my $name_original = $name;
	$name .= " $id"; 
	$names{$name_original} = $name;
	$chromosomes{$name_original} = $name if ($definition =~ m|chromosome \d+?,| and not $chromosomes{$name_original}); 
	$chromosomes{$name_original} .= " [$id]" if ($chromosomes{$name_original}); 
	
	my %warnings;
	
	#Skips if there are no tRNA annotations
	unless ($accession_data =~ m!\s{5,}(tRNA\s{5,}.+(?:\s{10,}.+){1,})!) {
		print "$name -> no tRNAs found!\n";
	    print OUT7 ">$name	[No tRNAs found]\n";
		$warnings{'*No tRNAs found'} = "SKIPPED no tRNAs found!";
		undef $accession_data;
		next;
	}
	
	$organism =~ s/^[\s]+//g;
	$organism =~ s/\s{2,}/ /g;

	my $group = 'UNDEFINED';
	if ($organism =~ m|Eukaryota; Viridiplantae; (.+?);|i){
		$group = $1;
	} elsif ($organism =~ m|Eukaryota; (.+?);|i) {
		$group =  $1;
	} elsif ($organism =~ m|(.+?);|i) {
		$group =  $1;
	}

	# $group = 'Rhodophytes' if ($organism =~ m|Rhodophyta|i);
	# $group = 'Glaucophytes' if ($organism =~ m|Glaucocystophyceae|i);
	# $group = 'Euglenids' if ($organism =~ m|Euglenozoa|i);
	# $group = 'Cercozoans' if ($organism =~ m|Cercozoa|i);
	# $group = 'Cercozoans' if ($organism =~ m|Cercozoa|i);

	
	$sequence = $1 if ($accession_data =~ m/ORIGIN([\W\w]+)\n\/\//);
	$sequence =~ s/[\W\d]+//g;
	
	my $tRNA_total = 0;
	my $tRNA_standard = 0;
	my $anticodon_total = 0;
	my @tRNA_count = (0)x20;
	my %anticodon_count = (
		'AGC', 0,
		'GGC', 0,
		'CGC', 0,
		'TGC', 0,
		'ACC', 0,
		'GCC', 0,
		'CCC', 0,
		'TCC', 0,
		'AGG', 0,
		'GGG', 0,
		'CGG', 0,
		'TGG', 0,
		'AGT', 0,
		'GGT', 0,
		'CGT', 0,
		'TGT', 0,
		'AAC', 0,
		'GAC', 0,
		'CAC', 0,
		'TAC', 0,
		'AGA', 0,
		'GGA', 0,
		'CGA', 0,
		'TGA', 0,
		'ACT', 0,
		'GCT', 0,
		'ACG', 0,
		'GCG', 0,
		'CCG', 0,
		'TCG', 0,
		'CCT', 0,
		'TCT', 0,
		'AAG', 0,
		'GAG', 0,
		'CAG', 0,
		'TAG', 0,
		'CAA', 0,
		'TAA', 0,
		'AAA', 0,
		'GAA', 0,
		'ATT', 0,
		'GTT', 0,
		'CTT', 0,
		'TTT', 0,
		'ATC', 0,
		'GTC', 0,
		'CTC', 0,
		'TTC', 0,
		'ATG', 0,
		'GTG', 0,
		'CTG', 0,
		'TTG', 0,
		'ATA', 0,
		#'CTA', 0,
		#'TTA', 0,
		#'TCA', 0,
		'GTA', 0,
		'AAT', 0,
		'GAT', 0,
		'TAT', 0,
		'CAT', 0,
		'ACA', 0,
		'GCA', 0,
		'CCA', 0
	);
	my $unknown_anticodons = 0;
	my %AA_to_find;
	my %seq_to_find;
	
	
############################
####### tRNAs search #######
############################
	
	open (TRNASEQ, ">", "tRNASEQ.txt") or die "Cannot write the tRNA sequence file";
	
	print "$name\n\t$definition\n";
	
	print "Phase I - Searching for tRNA annotations..\n";
	##tRNA count
	while ($accession_data =~ m!\s{5,}(tRNA\s{5,}.+(?:\s{10,}.+){1,})!g){
		my $tRNA_annotation = $1;
		++$tRNA_total;
		
		my $location = $1 if ($tRNA_annotation=~ m|tRNA\s+((?:complement\()?(?:join\()?([\.,\d]+)\)?\)?)|); 
		
		if ($tRNA_annotation =~ m!(pseudo|pseudogene)!i){ #Skips if it is annotated as a pseudogene
			$warnings{'*Pseudo tRNA Annotation [#position]'} .= "#$tRNA_total - $location ";
			next;
		}
		if ($tRNA_annotation=~ m!\/gene=".+?(fM|fMet).*?"!i){
			print "fM or fMet is being skipped.\n";
			$warnings{'*fMet Annotation [#position]'} .= "#$tRNA_total - $location ";
			next;
		}; #skip trnfM, formyl-Methionine 
		my $AA = '';
		my $anticodon = '';

	
		if ($tRNA_annotation=~ m|\/gene="trn([A-Z])(-\w+)?"|) { # 1 letter code es. trnE when product="/product="tRNA-OTHER" as in Cyanophora paradoxa cyanelle
			$AA = $one_letter2three_letter{$1}; 
			unless (exists $AA2anticodons{$AA}) { #Skips if it is not a standard AA
				print "$AA is being skipped.\n";
				$warnings{'*Non-standard tRNA Annotation [#position]'} .= "#$tRNA_total - $location ";
				next;
			}	
			my $index = first { (lc($tRNA[$_])) eq (lc($AA)) } 0..$#tRNA;
			if (defined $index) {
				++$tRNA_count[$index];
			}
			if ($tRNA_annotation=~ m|\/product="tRNA-(\w{3})"|i){
				my $product = $1;
				if (uc $product ne uc $AA){
					print "Gene name and product do not match: Gene for $AA but the product shown is $product\n"; #e.g. NC_022431.1 in complement(36270..36343)
					$warnings{'*MISSMATCH Gene and Product annotations do not agree [#position]'} .= "#$tRNA_total - $location "; 
				}
			}
						
		} elsif ($tRNA_annotation=~ m|\/product="tRNA-(\w{3})"|i){
			$AA = $1; 
			unless (exists $AA2anticodons{$AA}) {
				print "$AA is being skipped.\n";
				$warnings{'*Non-standard tRNA Annotation [#position]'} .= "#$tRNA_total - $location ";
				next;
			}	#Skips if it is not a standard AA
			my $index = first { (lc($tRNA[$_])) eq (lc($AA)) } 0..$#tRNA;
			if (defined $index) {
				++$tRNA_count[$index];
			}
		} else {
			$warnings{'*Non-standard tRNA Annotation [#position]'} .= "#$tRNA_total - $location ";
			next;	#Not a standard tRNA annotation
		}
		
		++$tRNA_standard;

		## Anticodon ONLY for STANDARD AA
		## This order accounts for modifications like CYTOSINE->LYSIDINE, if the annotation is present.

		if ($tRNA_annotation=~ m!\/codon_recognized:\s?([AUGCT]{3})"!i) {
			$anticodon = uc $1;
			$anticodon =~ s/U/T/g;
			$anticodon = &reverse_complement($anticodon);
		}elsif ($tRNA_annotation=~ m!\/codon_recognized="([AUGCT]{3})"!i) {    #NC_004766.1, NC_014062.1, trnfM is discarded?
			$anticodon = uc $1;
			$anticodon =~ s/U/T/g;
			$anticodon = &reverse_complement($anticodon);
		# }elsif ($tRNA_annotation=~ m!\/note="trn\w\w?[-(]([AUGCT]{3})!i) {    #NC_004766.1, NC_014062.1, also trnfM is recognized 
		}elsif ($tRNA_annotation=~ m!\/note="trn\w[-(]([AUGCT]{3})!i) {    #NC_004766.1, NC_014062.1, trnfM is discarded?
			$anticodon = uc $1;
			$anticodon =~ s/U/T/g;
		# }elsif ($tRNA_annotation=~ m!\/gene="trn\w\w?[-(]([AUGCT]{3})!i) {    #NC_020319.1, also trnfM is recognized
		}elsif ($tRNA_annotation=~ m!\/gene="trn\w[-(]([AUGCT]{3})!i) {    #NC_020319.1, trnfM is discarded
			$anticodon = uc $1;
			$anticodon =~ s/U/T/g;
		}elsif ($tRNA_annotation=~ m!trna-\w{3}\s?\(([AUGCT]{3})\)!i) {    #NC_016753.1, NC_001320.1 /gene="tRNA-Lys(UUU)" or /note="trnQ; tRNA-Gln(UUG)"
			$anticodon = uc $1;
			$anticodon =~ s/U/T/g;
		}elsif ($tRNA_annotation=~ m!anticodon:?\s?([AUGCT]{3})!i) { #NC_001568.1  /note="anticodon tgc", /note="anticodon: tgc", /note="anticodon:tgc",  tRNA-Val (anticodon: AAC)"
			$anticodon = uc $1;
			$anticodon =~ s/U/T/g;
		}elsif ($tRNA_annotation=~ m!/anticodon=.+(?:\n.+)?seq:([AUGCT]{3})!i) { #NC_014874.1 e.g. /anticodon=(pos:60389..60391,aa:Leu,seq:caa), #NC_001568.1 is odd.
			$anticodon = uc $1;
			$anticodon =~ s/U/T/g;	
		}
	
	
		if (defined $anticodon2AA{$anticodon} and uc $anticodon2AA{$anticodon} eq uc $AA) {
			++$anticodon_count{$anticodon};
			++$anticodon_total;		
			# print "$AA($anticodon)->$anticodon2AA{$anticodon}\n";
		}elsif (defined $anticodon2AA{&reverse_complement($anticodon)} and uc $anticodon2AA{&reverse_complement($anticodon)} eq uc $AA) { #Tries to overcame some annotation errors/odd annotations, eg. NC_020319.1 codons instead of anticodons
			my $rev_anticodon = &reverse_complement($anticodon);
			++$anticodon_count{$rev_anticodon};
			++$anticodon_total;
			
			$warnings{'*MISSMATCH Codon and anticodon annotations do not agree [#position]'} .= "#$tRNA_total - $location ($AA($anticodon)->$anticodon2AA{$rev_anticodon}($rev_anticodon))";
			
			print "$AA($anticodon) Codon/Anticodon Typo mistake? ->$anticodon2AA{$rev_anticodon}($rev_anticodon)\n";
		}elsif (defined $anticodon2AA{$anticodon} and (uc $anticodon2AA{$anticodon} eq 'MET' and uc $AA eq 'ILE')){		
			$anticodon = 'TAT';	#assigns tRNA-CAU to Ile when specified in the annotation
			++$anticodon_count{$anticodon};
			++$anticodon_total;	
			$warnings{'*tRNA-CAU annotated as tRNA-Ile (not Met) [#position]'} .= "#$tRNA_total - $location ";	
		}else {
		#	print "$tRNA_annotation\n\nUnknown anticodon..searching..\n";
			++$unknown_anticodons;
			my $tRNA_seq = '';
			my $seq_position = '';
			my $seq_header = '';
			if ($tRNA_annotation=~ m|tRNA\s+((?:complement\()?join\(([\.,\d]+)\)\)?)|){  
				$seq_position = $2;
				$seq_header= $1;
				# print "\nprimo IF $1\n$2\n";
				# $seq_header =~ s/,.+//;

				my @parts = split (",", $seq_position);
				# print "header $seq_header\n";
				# print "parts array @parts\n";
				@parts = sort(@parts) if ($tRNA_annotation=~ m|tRNA\s+complement\(join\([\.,\d]+\)|);	#Erroneously, In some annotations the complement is done before the join, like c(part1)+c(part2)
				foreach (@parts){
					# print "part |$_|\n";
					my ($start, $end) = '';
					if ($_ =~ m|(\d+)\.\.(\d+)|){
						$start = $1;
						$end = $2;
						my $part_seq = substr ($sequence, $start-1, $end-$start+1);
						
						# print "part: |$part_seq| \n";
						$tRNA_seq .= $part_seq;
					} elsif ($_ =~ m|^(\d+)\$|) {
						$tRNA_seq .= substr ($sequence, $1, 1);
					}
				}
				$AA_to_find{$seq_header} = $AA if (length $tRNA_seq <= 10000 && length $tRNA_seq > 20);   #Discards sequences longer than 10000 and shorter than 20 AAs
			} elsif ($tRNA_annotation=~ m|tRNA\s+((?:complement\()?(\d+)\.\.(\d+)\)?)\n|){
					$seq_header = $1;
					my $start = $2;
					my $end = $3;
					#print "\nsecondo IF $start..$end\n";
					$tRNA_seq = substr ($sequence, $start-1, $end-$start+1);
					$AA_to_find{$seq_header} = $AA if (length $tRNA_seq<=10000 && length $tRNA_seq > 20);  #Discards sequences longer than 10000 and shorter than 20 AAs
					# print "\n$seq_header\n$tRNA_seq";
			}
			
			$tRNA_seq = uc $tRNA_seq;
			$seq_to_find{$seq_header} = $tRNA_seq;
			print TRNASEQ ">$seq_header\n$tRNA_seq\n" if (length $tRNA_seq <= 10000 && length $tRNA_seq > 20); #Discards sequences longer than 10000 and shorter than 20 AAs
			#print ">$seq_header\n$tRNA_seq\n";

		}		
		# print "$anticodon_total\n$anticodon\n\n";
	}
	
	print "tRNA annotations $tRNA_total	tRNA standard $tRNA_standard	ANTICODONS $anticodon_total	ND $unknown_anticodons\n\n";
	close (TRNASEQ);

#######Skips the whole genome record if it doesn't contain any tRNA standard annotated.	
	if ($tRNA_standard == 0){
		print "No STANDARD tRNAs found\n\n";
		print OUT7 ">$name	[No STANDARD tRNAs found]\n";	
		next;
	}
	
	#Scanning with tRNAscan
	my $tRNAscan_success=0;
	if ($unknown_anticodons>0) {
		
		# $warnings{'*tRNAscan-SE analysis'} = 'SUCCESS';
		
		open (TRNASCAN_LOG, ">", "tRNASEQ LOG.txt") or die "Cannot write tRNAscan LOG file";

		my $tRNAscan = '';
		
		# tRNAscan-SE 2.0
	
		# -E                          : search for eukaryotic tRNAs (default)
		# -B                          : search for bacterial tRNAs
		# -A                          : search for archaeal tRNAs
		# -M <model>                  : search for mitochondrial tRNAs, options: mammal, vert
		# -O                          : search for other organellar tRNAs
		# -G                          : use general tRNA model (cytoslic tRNAs from all 3 domains included)
		# --mt <model>                : use mito tRNA models for cytosolic/mito detemination (if not specified, only cytosolic isotype-specific model scan will be performed)

		# --brief					: brief output format (no column headers)
		# -Q  						: do not prompt user before overwriting pre-existing result files(for batch processing)
		# -q  --quiet               : quiet mode (credits & run option selections suppressed)

		if ($organism =~ m|bacteria|i) {
			print "Phase II - ** Bacterial Genome ** tRNAscan-SE is searching for bacterial tRNAs..\n";
			$tRNAscan = `tRNAscan-SE -B -Q -q --brief /home/tRNASEQ.txt 2>&1`; #Uses the covariance model specific for bacteria genomes
		} elsif (($definition =~ m!(plastid|chloroplast|apicoplast|chromatophore|cyanelle|mithocondrion)!i) or ($source =~ m!(plastid|chloroplast|apicoplast|chromatophore|cyanelle|mithocondrion)!i)){
			print "Phase II - ** Organellar Genome ** tRNAscan-SE is searching for organellar tRNAs..\n";	
			$tRNAscan = `tRNAscan-SE -O -Q -q --brief /home/tRNASEQ.txt 2>&1`; #Uses the covariance model specific for plastids/mitochondria genomes, disabling the PSEUDOGENES check
		} elsif ($definition =~ m!(chromosome)!i){
			print "Phase II - ** Eukariotic Genome ** tRNAscan-SE is searching for eukariotic tRNAs..\n";	
			$tRNAscan = `tRNAscan-SE -E -Q -q --brief /home/tRNASEQ.txt 2>&1`; #Uses the covariance model specific for : search for eukaryotic tRNAs
		}else {
			print "Phase II - ** Nuclear or Unspecified Genome ** tRNAscan-SE is searching for generic tRNAs..\n";
			$tRNAscan = `tRNAscan-SE -G -Q -q --brief /home/tRNASEQ.txt 2>&1`; #Uses the generic covariance model
		}

		print TRNASCAN_LOG ">$name\n";
		print TRNASCAN_LOG "$tRNAscan\n\n";
		
		if ($tRNAscan =~ m/\.fpass for writing.\s+Aborting program./g){
			die "\n\n ****** STOPPED - Infernal hasn't been installed properly. ****** \n\n";
		}

		while ($tRNAscan =~ m%(.+?)(?:\s+\d+?){3}\s+(\w{3}|Pseudo)\s+(\w{3})\s%g){   #Read also PSEUDOGENES from tRNAscan
			my $seq = $1;
			my $AA = $2;
			my $anticodon = uc $3;
			# print "$seq $AA $anticodon\n";
			
			if ($AA eq 'Pseudo') {
				print "$AA gene\n";
				$warnings{'*tRNAscan-SE Pseudogene found'} .= "\n		$seq";
			}
			
			if ((uc $AA eq 'MET') and (uc $AA_to_find{$seq} eq 'ILE')){	
			        #Allow Lysidine exception for CAT anticodon. 
					#C in the first position of the anticodon
                    #assumed to be post-transcriptionally modified to lysidine,
                    #which pairs with A rather than G like does tRNA-Methionine.
                    #anticodon post-transcriptionally modified to have tRNA.
					#E.g Arabidopsis thaliana, NC_000932.1.
				$AA = 'ILE';
				$anticodon = 'TAT';
				$warnings{'*MISSMATCH Ile/Met from tRNAscan-SE (assuming Cytosine to Lysidine Mod)'} .= "$seq";
			}
			if (uc $AA ne uc $AA_to_find{$seq}){		#Skips if the tRNA anticodon predicted by tRNAscanSE is different from the annotated one.
				$AA_to_find{$seq} = "MISMATCH: tRNAscan found $anticodon->$AA instead of the annotated $AA_to_find{$seq}";
				$warnings{'*MISMATCH tRNAscan Amino Acid vs Annotated AA'} = "$anticodon->$AA instead of $AA_to_find{$seq}	$seq";
				next;
			} 

			delete $AA_to_find{$seq};
			++$tRNAscan_success;
			$anticodon =~ s/U/T/g;
			++$anticodon_count{$anticodon} if exists $anticodon_count{$anticodon};
			++$anticodon_total if exists $anticodon_count{$anticodon};
		}
		close TRNASCAN_LOG;
		
		print "tRNAscan-SE AAs not found:\n" if %AA_to_find;
		foreach (keys %AA_to_find) {
			print "	$_	$AA_to_find{$_}\n";
		}			
	
		
		if (%warnings){		#Dont change the order, or remember to change the file headers
			print "*** SEE WARNINGS ***\n\n";
			print OUT8 ">$name	tRNA annotations $tRNA_total tRNA standard $tRNA_standard ANTICODONS $anticodon_total ND $unknown_anticodons";
			print OUT8 "\t";
			print OUT8 "$warnings{'*Pseudo tRNA Annotation [#position]'}" if $warnings{'*Pseudo tRNA Annotation [#position]'};
			print OUT8 "\t";
			print OUT8 "$warnings{'*fMet Annotation [#position]'}" if $warnings{'*fMet Annotation [#position]'};
			print OUT8 "\t";
			print OUT8 "$warnings{'*Non-standard tRNA Annotation [#position]'}" if $warnings{'*Non-standard tRNA Annotation [#position]'};	
			print OUT8 "\t";
			print OUT8 "$warnings{'*MISSMATCH Gene and Product annotations do not agree [#position]'}" if $warnings{'*MISSMATCH Gene and Product annotations do not agree [#position]'};			
			print OUT8 "\t";
			print OUT8 "$warnings{'*MISSMATCH Codon and anticodon annotations do not agree [#position]'}" if $warnings{'*MISSMATCH Codon and anticodon annotations do not agree [#position]'};		
			print OUT8 "\t";
			print OUT8 "$warnings{'*tRNA-CAU annotated as tRNA-Ile (not Met) [#position]'}" if $warnings{'*tRNA-CAU annotated as tRNA-Ile (not Met) [#position]'};	
			print OUT8 "\t";
			print OUT8 "$warnings{'*tRNAscan-SE Pseudogene found'}" if $warnings{'*tRNAscan-SE Pseudogene found'};		
			print OUT8 "\t";
			print OUT8 "$warnings{'*MISSMATCH Ile/Met from tRNAscan-SE (assuming Cytosine to Lysidine Mod)'}" if $warnings{'*MISSMATCH Ile/Met from tRNAscan-SE (assuming Cytosine to Lysidine Mod)'};
			print OUT8 "\t";			
			print OUT8 "$warnings{'*MISMATCH tRNAscan Amino Acid vs Annotated AA'}" if $warnings{'*MISMATCH tRNAscan Amino Acid vs Annotated AA'};
			print OUT8 "\n";
		}
		
		
#######Skips the whole genome record if tRNAscan fail to identify all the missing codons
		unless ($anticodon_total == $tRNA_standard) {
			
			print OUT7 ">$name	[tRNAscan-SE failed to find the missing anticodons]\n";

			print "tRNAscan-SE failed to find the missing anticodons ($tRNAscan_success\/$unknown_anticodons).. discarding data.\n";
			
			print OUT8 ">$name\n" unless %warnings;
			print OUT8 "	*SKIPPED - tRNAscan-SE failed to find missing anticodons ($tRNAscan_success\/$unknown_anticodons)\n";
			foreach (keys %AA_to_find) {
				print OUT8 "		$_	$AA_to_find{$_}\n";
				print OUT8 "		> $seq_to_find{$_} < \n";
			}

			
			# print "WARNINGS $warnings{'*tRNAscan LOG'}\n";
			
			undef $accession_data;
			undef %warnings;
			next;
		}
#######################
	
		undef %warnings;
		
		print "FINISHED - Anticodons FOUND\n\n";

	}


	my $tRNA_species;
	foreach (keys %anticodon_count){	
		if ($anticodon_count{$_} > 0){
			++$tRNA_species;
		}
	}
	
	#OUTPUT
	
	if ($chromosomes{$name_original} and $results{$name_original}){
		$results{$name_original}[3] += $size; 
		$results{$name_original}[7] += $tRNA_total; 
		$results{$name_original}[9] += $tRNA_standard; 
		$results{$name_original}[10] += $unknown_anticodons; 
		
		$results2{$name_original}[2] += $size; 
		$results2{$name_original}[6] += $anticodon_total;	
		
		$results3{$name_original}[2] += $size; 
		$results3{$name_original}[4] += $anticodon_total;
	}
	
	$results{$name} = "$name	$definition	$group	$size	$id	$organism	$date	$tRNA_total	$tRNA_species	$tRNA_standard	$unknown_anticodons	";
	$results2{$name} = "$name	$group	$size	$id	$organism	$date	$anticodon_total	";
	$results3{$name} = "$name	$group	$size	$organism	$anticodon_total	$tRNA_species	";
	$results4{$name} = "$name	$group	";
	$results5{$name} = "$name	$group	";
	$results6{$name} = "$name	$group	";
	
	if ($chromosomes{$name_original} and not $results{$name_original}) {
		$results{$name_original} = [$name_original, "Whole Genome", $group, $size, $chromosomes{$name_original}, $organism, 'Undefined', $tRNA_total, $tRNA_species, $tRNA_standard, $unknown_anticodons];
		$results2{$name_original} = [$name_original, $group, $size, $chromosomes{$name_original}, $organism, 'Undefined', $anticodon_total];
		$results3{$name_original} = [$name_original, $group, $size, $organism, $anticodon_total, $tRNA_species];
		$results4{$name_original} = [$name_original, $group];
		$results5{$name_original} = [$name_original, $group];
		$results6{$name_original} = [$name_original, $group];
	}
	
	
	foreach (0..$#tRNA_count) {
		$results{$name} .= "$tRNA_count[$_]	";
	}
	foreach (sort keys %AA2anticodons){
		my $ref = $AA2anticodons{$_};
		foreach (sort @$ref){		
			$results2{$name} .= "$anticodon_count{$_}	";
		}
	}
	
	my %tot_codon_per_AA;
	my %codon_count = ();
	foreach (keys %anticodon_count){			
		my $codon = &reverse_complement($_);
		$codon_count{$codon} = $anticodon_count{$_};
		$tot_codon_per_AA{$codon2AA{$codon}} += $codon_count{$codon};
	}	
	

	foreach (sort keys %AA2codons){
		my $AA = $_;
		my $ref = $AA2codons{$AA};
		foreach (sort @$ref){	
			my $codon = $_;
			# print "\n$codon_count{$codon}";
			# print "\n$AA $tot_codon_per_AA{$AA}";
			# print "\n", scalar @$ref;
			my $rgf;
			if ($tot_codon_per_AA{$AA} == 0) {
				$rgf = 0;
			} else {
				$rgf = ($codon_count{$codon}/$tot_codon_per_AA{$AA})*(scalar @$ref);
			}
			# print "\nRGF = $rgf";
			# <>;
			# print OUT3 "$codon $codon_count{$codon} ($rgf)	";
			$results3{$name} .= "$codon $codon_count{$codon}	";	
			$results4{$name} .= "$codon_count{$codon}	";
			$results5{$name} .= $rgf."	";
			$results6{$name} .= $rgf*($tRNA_species/$anticodon_total)."	";
		}
	}

	
	$results{$name} .= "\n";
	$results2{$name} .= "\n";
	$results3{$name} .= "\n";
	$results4{$name} .= "\n";
	$results5{$name} .= "\n";
	$results6{$name} .= "\n";

	undef $accession_data;
	undef $unknown_anticodons;
	undef %AA_to_find;
	undef %seq_to_find;

}


	
foreach (sort keys %results){
	if (ref $results{$_}) {
		print OUT join("\t", @{$results{$_}})."\n";
		print OUT2 join("\t", @{$results2{$_}})."\n" if $out2;
		print OUT3 join("\t", @{$results3{$_}})."\n";
		print OUT4 join("\t", @{$results4{$_}})."\n";
		print OUT5 join("\t", @{$results5{$_}})."\n" if $out5;
		print OUT6 join("\t", @{$results6{$_}})."\n" if $out6;
	} else {
		print OUT "$results{$_}";
		print OUT2 "$results2{$_}" if $out2;
		print OUT3 "$results3{$_}";
		print OUT4 "$results4{$_}";
		print OUT5 "$results5{$_}" if $out5;
		print OUT6 "$results6{$_}" if $out6;
	}
}


my $end_time   = new Benchmark;
my $difference = timediff($end_time, $start_time);
print "##### Benchmark #####\n: It took ", timestr($difference), "!\n";

close DATA;
close OUT;
close OUT2 if $out2;
close OUT3;
close OUT4;
close OUT5 if $out5;
close OUT6 if $out6;
close OUT7;
close OUT8;

print "\nDONE";

sub reverse_complement {
        my $dna = shift;

	# reverse the DNA sequence
        my $revcomp = reverse($dna);

	# complement the reversed DNA sequence
        $revcomp =~ tr/ACGTUacgtu/TGCAAtgcaa/;
        return $revcomp;
}

exit;

