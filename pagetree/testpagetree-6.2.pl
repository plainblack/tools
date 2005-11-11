#!/usr/bin/perl


our ($webguiRoot, $configFile);

BEGIN {
        $configFile = "www.plainblack.com.conf";
        $webguiRoot = "/data/WebGUI";
        unshift (@INC, $webguiRoot."/lib");
}

#-----------------DO NOT MODIFY BELOW THIS LINE--------------------

use CGI::Carp qw(fatalsToBrowser);
use strict;
use WebGUI;
use WebGUI::SQL;

print "Starting up.\n";

WebGUI::Session::open( $webguiRoot,$configFile);

print "Reading tree from database. \n";
my $sth = WebGUI::SQL->read("select pageId, nestedSetLeft, nestedSetRight from page");

my (%left, %right, %leftRightError, $max);

while (my %row = $sth->hash) {
$left{$row{nestedSetLeft}}++;
$right{$row{nestedSetRight}}++;
$leftRightError{$row{pageId}} = 1 if ($row{nestedSetLeft} > $row{nestedSetRight});
$max = $row{nestedSetRight} if $row{nestedSetRight} > $max;
}

print "Checking for left doubles\n";
foreach (keys %left) {
print "Left error: $_ ($left{$_} x)\n" if $left{$_} > 1;
print "Error, also as right identifier: $_\n" if $right{$_} > 0;
}

print "Checking for right doubles\n";
foreach (keys %right) {
print "Right error: $_ ($right{$_} x)\n" if $right{$_} > 1;
}

print "Checking for left-right per node consistency\n";
foreach (keys %leftRightError) {
print "Left-right error on page: $_\n";
}

print "Checking for gaps\n";
for (0..$max) {
print "Gap found at: $_\n" unless (defined $left{$_} || defined $right{$_});
}


