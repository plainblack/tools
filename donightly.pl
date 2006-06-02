#!/data/wre/prereqs/perl/bin/perl
our ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
$mon += 1;
$mon = sprintf("%02d",$mon);
$year = sprintf("%04d",$year);
$mday = sprintf("%02d",$mday);
system("TEST_SYNTAX=1 /data/tools/makerelease.pl --version=nightly_".$year."-".$mon."-".$mday." --generateCreateScript;/data/tools/makedocs.pl --version=nightly_".$year."-".$mon."-".$mday);
