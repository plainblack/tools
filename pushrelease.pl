#!/data/wre/prereqs/bin/perl

use Getopt::Long;
use File::Path;

our $version = "";
our $buildDir = "/data/builds";
our $branch = "";

GetOptions(
	'version=s'=>\$version,
	'buildDir=s'=>\$buildDir,
	'buildDir=s'=>\$branch
	);


if ($version ne "") {
	createTag();
	publishToPb();
	publishToSf();
} else {
	print <<STOP;
	Usage: $0 --version=0.0.0

	Options:

	--branch		If this release was from a branch, specify that here

	--buildDir		The base directory to create all builds in. Defaults to /data/builds.

	--version		The build version. Used to create folders and filenames.

STOP
}

sub createTag {
	print "Creating a release tag for ".$version." in subversion.\n";
	if ($branch) {
		system('svn copy -m "Release '.$version.'" https://svn.webgui.org/plainblack/branch/'.$branch.' https://svn.webgui.org/plainblack/releases/WebGUI_'.$version);
	}
	else {
		system('svn copy -m "Release '.$version.'" https://svn.webgui.org/plainblack/WebGUI https://svn.webgui.org/plainblack/releases/WebGUI_'.$version);
	}
}

sub publishToPb {
	print "Publishing version ".$version." to the Plain Black web server.\n";
	my @versions = split(/\./,$version);
	system("cp -Rf ".$buildDir."/".$version."/webgui-".$version.".tar.gz /data/domains/update.webgui.org/public/".$versions[0].".x.x/");
	open(FILE,">/data/domains/update.webgui.org/public/latest-version.txt");
	print FILE $version;
	close(FILE);
	system("rm -f /data/domains/plainblack.com/www/public/downloads/webgui-latest.tar.gz");
	system("cd /data/domains/plainblack.com/www/public/downloads;ln -s /data/domains/update.webgui.org/public/".$versions[0].".x.x/webgui-".$version.".tar.gz webgui-latest.tar.gz");
}

sub publishToSf {
	print "Publishing version ".$version." to the Source Forge FTP server.\n";
	system('/usr/bin/lftp -e "put -O incoming '.$buildDir.'/'.$version.'/webgui-'.$version.'.tar.gz; exit" -u anonymous,nopass ftp://upload.sf.net');
}

