tRNA tools - by Mattia Belli 2013-2018
====

Perl scripts to analyze tRNA gene content, codon frequency and their correlation in genomes.

BASED on:

* tRNAscan-SE
Lowe, T.M. & Chan, P.P. (2016) Nucl. Acids Res. 44: W54-57.

Lowe, T.M. & Eddy, S.R. (1997) Nucl. Acids Res. 25: 955-964.

* CodonW 1.4.4 http://codonw.sourceforge.net/

-------------------------------------------------------------------------

** SYSTEM REQUIREMENTS **


All scripts are written in Perl programming language. A Perl interpreter has to be installed.

tRNAscan-SE binaries are compiled for UNIX machines so you need UNIX-based OS or CygWin for Windows OS.

MANDATORY

1) Install a Perl interpreter
OPTIONAL 
Add Bribes and Trouchelle repositories:
- ppm rep add Bribes http://www.bribes.org/perl/ppm
- ppm rep add Trouchelle http://trouchelle.com/ppm

2) Install the following Perl modules:
- List::Util
- LWP
- Statistics::RankCorrelation
- Statistics::Distributions
- Statistics::R (at least version 0.33)

OPTIONAL 
To use all the features of CORR checker
3) Install R:
- http://www.r-project.org/

4) Install the package "coin".
