#!/data/wre/prereqs/bin/perl
use Getopt::Long;

our $version = "";
my $help;
my $branch = "";

GetOptions(
	'version=s'=>\$version,
	'help'=>\$help,
	'branch=s'=>\$branch,
	);

if ($help || $version !~ m/\d+\.\d+\.\d+\-\w+/) {
print <<STOP;

usage $0 --version=7.3.18-stable

--branch	checks out from a branch rather than head

--help		display this message

--version	the version we're releasing

STOP
	exit;
}

system("/data/tools/makerelease.pl --version=$version --branch=$branch;/data/tools/makedocs.pl --version=$version");
