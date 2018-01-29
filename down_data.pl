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
 
use strict;
use LWP;
use Encode;

my $client = LWP::UserAgent->new('agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:14.0) Gecko/20100101 Firefox/14.0.1', keep_alive => 1, timeout => 30);
my $base = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/';

my $query;
my @acc;
my $data;
my $api_option = ''; # Insert here the API key Registered through NCBI account
my $chunk_size = 50;

open (INPUT_FILE, "<", 'accession_numbers.txt') || die "Can't open file!\n";
open (OUTPUT_FILE, ">", 'ncbi_data.txt') || die "Can't write file!\n";;

print "Loading data..\n";
while (<INPUT_FILE>){
	my $ustring = decode( 'UTF-8', $_ ); #Avoid wide characters in the accession list
	$ustring =~ s/\W+//;
	$ustring =~ s/.+\://;
	push (@acc, $ustring);
}

close INPUT_FILE;

print @acc;


my $n;
while ( my @chunk = splice (@acc, 0, $chunk_size) ) {
	++$n;
	print "Processing Chunk $n\n";
	$query = join (",", @chunk);
	&download;
}

print OUTPUT_FILE $data;
close OUTPUT_FILE;

exit; 

sub download {
	#assemble the esearch URL
	my $esearch_url = $base . "esearch.fcgi?db=nuccore&term=$query&usehistory=y$api_option&retmax=$chunk_size";
	print "	$esearch_url\n";
	
	print "	Searching..\n";
	my $esearch = $client->get($esearch_url);
	print $esearch->status_line unless $esearch->is_success;
	my $esearch_response = $esearch->decoded_content;
	# print "\n*****\n$esearch_response\n*****\n";
	
	my @errors = ();
	while ($esearch_response =~ m/<PhraseNotFound>(\S+)<\/PhraseNotFound>/g){
		push (@errors, $1);
	}
	
	if (@errors){
		die "\nWARNING: The following term(s) gave errors: @errors\n\nPlease correct the list and perform the download again.\n";
	}
	
	sleep(0.5);
	
	#parse WebEnv, QueryKey and Count (# records retrieved)
	my $web = $1 if ($esearch_response =~ m/<WebEnv>(\S+)<\/WebEnv>/);
	my $key = $1 if ($esearch_response =~ m/<QueryKey>(\d+)<\/QueryKey>/);
	my $count = $1 if ($esearch_response =~ m/<Count>(\d+)<\/Count>/);
	
	print "	Downloading..\n";
	my $efetch_url = $base ."efetch.fcgi?db=nuccore&WebEnv=$web&query_key=$key&rettype=gb&retmode=text$api_option";
	my $efetch = $client->get($efetch_url);
	# print $efetch->status_line unless $efetch->is_success;
	sleep(0.5);
	
	print "	Saving..\n";
	$data .= $efetch->decoded_content;
	$data =~ s/\r//g; #Removes carriage returns changing the EOF from CRLR to LR only,
					  #otherwise findtrna.pl could give errors during pattern matching
	
	print "Done.\n\n";		
}

