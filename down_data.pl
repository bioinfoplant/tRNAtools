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

my $client = LWP::UserAgent->new('agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:14.0) Gecko/20100101 Firefox/14.0.1', keep_alive => 1, timeout => 30);
my $base = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/';

my $query;
my @acc;
my $data;
my $api_option = '&api_key=ebe53cc33800b2a9c2f69fc5bc0047b58e08'; #Registered through NCBI account

open (INPUT_FILE, "<", 'accnumber.txt') || die "Can't open file!\n";
open (OUTPUT_FILE, ">", 'data.txt') || die "Can't write file!\n";;

print "Loading data..\n";
foreach (<INPUT_FILE>){
	$_ =~ s/[^\w\.]//g;
	push (@acc, $_);
}

close INPUT_FILE;

my $n;
while ( my @chunk = splice (@acc, 0, 50) ) {
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
	my $esearch_url = $base . "esearch.fcgi?db=nuccore&term=$query&usehistory=y$api_option";
	print "$esearch_url\n";
	
	print "	Searching..\n";
	my $esearch = $client->get($esearch_url);
	print $esearch->status_line unless $esearch->is_success;
	my $esearch_response = $esearch->decoded_content;
	sleep(0.5);
	
	#parse WebEnv, QueryKey and Count (# records retrieved)
	my $web = $1 if ($esearch_response =~ /<WebEnv>(\S+)<\/WebEnv>/);
	my $key = $1 if ($esearch_response =~ /<QueryKey>(\d+)<\/QueryKey>/);
	my $count = $1 if ($esearch_response =~ /<Count>(\d+)<\/Count>/);
	
	print "	Downloading..\n";
	my $efetch_url = $base ."efetch.fcgi?db=nuccore&WebEnv=$web&query_key=$key&rettype=gb&retmode=text$api_option";
	my $efetch = $client->get($efetch_url);
	print $efetch->status_line unless $efetch->is_success;
	sleep(0.5);
	
	print "	Saving..\n";
	$data .= $efetch->decoded_content;
	
	print "Done.\n\n";		
}

