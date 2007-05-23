#!/data/wre/prereqs/perl/bin/perl
use Getopt::Long;

our $version = "";
my $help;

GetOptions(
	'version=s'=>\$version,
	'help'=>\$help,
	);

if ($help || $version !~ m/\d+\.\d+\.\d+\-\w+/) {
print <<STOP;

usage $0 --version=7.3.18-stable

--help		display this message

--version	the version we're releasing

STOP
	exit;
}

system("/data/tools/makerelease.pl --version=$version;/data/tools/makedocs.pl --version=$version");
