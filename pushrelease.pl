#!/usr/bin/perl 

use Getopt::Long;
use File::Path;

our $version = "";
our $buildDir = "/data/builds";
our $pbPublishDir = "/data/domains/plainblack.com/www/public/downloads";
our $sfPublishServer = "upload.sf.net";
our $sfPublishPath = "/incoming";
our $ncftpput = "/usr/bin/ncftpput";

GetOptions(
	'version=s'=>\$version,
	'buildDir=s'=>\$buildDir
	);


if ($version ne "") {
	publishToPb();
	publishToSf();
} else {
	print <<STOP;
	Usage: $0 --version=0.0.0

	Options:

	--buildDir		The base directory to create all builds in. Defaults to /data/builds.

	--version		The build version. Used to create folders and filenames.

STOP
}


sub publishToPb {
	print "Publishing version ".$version." to the Plain Black web server.\n";
	my @versions = split(/\./,$version);
	system("cp -Rf ".$buildDir."/".$version."/webgui-".$version.".tar.gz ".$pbPublishDir."/".$versions[0].".x.x/");
	open(FILE,">/data/domains/plainblack.com/www/public/downloads/latest-version.txt");
	print FILE $version;
	close(FILE);
	system("rm -f ".$pbPublishDir."/webgui-latest.tar.gz");
	system("ln -s ".$pbPublishDir."/".$versions[0].".x.x/webgui-".$version.".tar.gz ".$pbPublishDir."/webgui-latest.tar.gz");
}

sub publishToSf {
	print "Publishing version ".$version." to the Source Forge FTP server.\n";
	system($ncftpput." ".$sfPublishServer." ".$sfPublishPath." ".$buildDir."/".$version."/webgui-".$version.".tar.gz");
}

