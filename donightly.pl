#!/usr/bin/perl
our ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
$mon += 1;
system("export CVS_RSH=ssh;export CVSROOT=:ext:rizen\@cvs.sourceforge.net:/cvsroot/pbwebgui;/data/tools/makerelease.pl --version=nightly-".$year."-".$mon."-".$mday." --generateCreateScript;/data/tools/makedocs.pl --pod2html=/data/perl582/bin/pod2html --version=nightly-".$year."-".$mon."-".$mday);
