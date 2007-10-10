#!/data/wre/prereqs/bin/perl
our ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
$mon += 1;
$mon = sprintf("%02d",$mon);
$year = sprintf("%04d",$year);
$mday = sprintf("%02d",$mday);
$hour = sprintf("%02d",$hour);
system("/data/tools/makerelease.pl --version=hourly_".$year."-".$mon."-".$mday."_".$hour." --generateCreateScript;/data/tools/makedocs.pl --version=hourly_".$year."-".$mon."-".$mday."_".$hour);
