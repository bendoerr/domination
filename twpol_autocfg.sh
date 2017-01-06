#!/usr/bin/perl
#
# Author:  Joshua M. Miller
# Date:    08/26/2004
#
# Purpose:  To automate the configuration of the tripwire policies.
#

use strict ;

my $file = "/etc/tripwire/twpol.txt" ;
my $new_file = "/etc/tripwire/new_twpol.txt" ;

print "Opening $file\n\n" ;

open INFILE, $file or die "Can't open input file : $!" ;
open OUTFILE, ">$new_file" or die "Can't open output file: $!" ;

print "Processing the current tripwire config file...\n" ;

while ( <INFILE> ) {

      # If it is a file that requires checking, check it to see if the file is on this system
      # If the line begins with a /, then we know it needs to be checked
      # If the file is not on this system, comment it out
      if (m{^\s+/\w}) {

              # Take the file's path from the line
              my @tst_file = split(/\s+/,$_) ;

              # Check to see if the file exists
              unless ( -e $tst_file[1] ) {
                      $_ = "#" . $_ ;
              }

	# Debug, print results
	#print "Result:  $tst_file[1]\n" ;


	# Test - print this section to the outfile
	#print OUTFILE "$tst_file[1]\n" ;
      }

      # Write the line to the new file
      print OUTFILE "$_" ;
}

close INFILE ;
close OUTFILE ;
