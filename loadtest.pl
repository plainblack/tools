#!/usr/bin/perl
$|=1;
my $site = "www.example.com";
my $user = "admin";
my $pass = "123qwe";
my $numUsers = 10;
my $minutesToRun = 3;
my $secondsBetweenClicks = 1;

use strict;
use WWW::Mechanize;


my @pids;
my $pid; 
for (1..$numUsers) {
	die "fork: $!" unless  defined ($pid = fork());
	if ($pid) {
		push(@pids,$pid);
	} else {
		run();
		exit;
	}
}

sub run {
	my $start = time();
	while (time()-$start < $minutesToRun*60) {
		print "\nATTENTION: Starting new worker.\n";
		doWork();
	}
}

sub doWork {
	my $agent = WWW::Mechanize->new();
	$agent->get("http://".$site."/");
	waitForIt();
	$agent->submit_form(
		form_number=>1,
		fields => {
			username=>$user,
			identifier=>$pass
			}
		);
	waitForIt();
	$agent->follow_link(text => "Turn Admin On!", n => "1");
	waitForIt();
	$agent->get("http://".$site."/index.pl/home?op=listUsers");
	waitForIt();
	$agent->follow_link(text => "Add a new user.", n => "1");
	waitForIt();
	$agent->get("http://".$site."/index.pl/home?op=listGroups");
	waitForIt();
	$agent->follow_link(text => "Add new group.", n => "1");
	waitForIt();
	$agent->get("http://".$site."/index.pl/home?op=manageSettings");
	waitForIt();
	$agent->follow_link(text => "Edit Profile Settings", n => "1");
	waitForIt();
}

sub waitForIt {
	sleep($secondsBetweenClicks);
}

