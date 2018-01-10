#!/usr/bin/perl 

use LWP;
use strict;
use POSIX 'strftime';

my $date = strftime '%Y-%m-%d', localtime;

my $client = LWP::UserAgent->new('agent' => 'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36', keep_alive => 1, timeout => 30);


print "Searching NCBI Genome..\n";
my $response = $client->get('https://www.ncbi.nlm.nih.gov/genomes/GenomesGroup.cgi?taxid=2759&opt=plastid');
print $response->status_line unless $response->is_success;
my $content = $response->decoded_content;

my $total;
open OUT, ">$date plastomes stats.txt" or die "Cannot save plastomes stats";
while ($content =~ m|<td nowrap><a data-jig="ncbilinksmenu".+?<i>(.+?)</i>.+?<span color="#6699CC">\[(.+?)\]</span></td>|sg){
	print "$1	$2\n";
	print OUT "$1	$2\n";
	$total+=$2;
}
print "TOTAL	$total\n";
print OUT "TOTAL	$total\n";

close OUT;
print "DONE\n";
<>;