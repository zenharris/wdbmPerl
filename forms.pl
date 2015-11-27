#!/usr/bin/perl
#
# @File forms.pl
# @Author harris
# @Created 12/09/2015 7:23:19 PM
#

use strict;
use POSIX;
use wdbm;


use primcmds;
use resiecmds;

our $dirconfig = "/home/harris/Programming/accounting/main/config";
our $iter;

wdbm->screen_handling_on();

if ($ARGV[0] eq "resie") {
	wdbm->form_view(wdbm->new("resie",$dirconfig,resiecmds->new()));
} elsif ($ARGV[0] eq "sewer") {
	wdbm->form_view(wdbm->new("prim",$dirconfig,primcmds->new()));
} else {
	print ("form resie|sewer\n");
} 

wdbm->flash("Exiting Database Forms");
wdbm->screen_handling_off();
print "\n\n";
