#!/data/wre/prereqs/bin/perl

use Getopt::Long;
use File::Path;

our $version = "";
our $buildDir = "/data/builds";
our $branch = "master";

GetOptions(
	'version=s'=>\$version,
	'buildDir=s'=>\$buildDir,
	'branch=s'=>\$branch
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

#sub createTag {
#	print "Creating a release tag for ".$version." in subversion.\n";
#	if ($branch) {
#		system('svn copy -m "Release '.$version.'" https://svn.webgui.org/plainblack/branch/'.$branch.' https://svn.webgui.org/plainblack/releases/WebGUI_'.$version);
#	}
#	else {
#		system('svn copy -m "Release '.$version.'" https://svn.webgui.org/plainblack/WebGUI https://svn.webgui.org/plainblack/releases/WebGUI_'.$version);
#	}
#}

sub createTag {
	print "Creating a release tag for ".$version." in git.\n";
	my $tag_name = $version;
	$tag_name =~ s/-\w+$//;
	system <<"EOCMD";
cd /data/git/webgui;       \
git checkout $branch;      \
git pull;                  \
git tag v$tag_name;        \
git push origin v$tag_name
EOCMD
}

sub publishToPb {
	print "Publishing version ".$version." to the Plain Black web server.\n";
	my @versions = split(/\./,$version);
	system("cp -Rf ".$buildDir."/".$version."/webgui-".$version.".tar.gz /data/domains/update.webgui.org/public/".$versions[0].".x.x/");
	my $versionFile = "latest-version.txt";
	if ( $version =~ /beta/) {
		$versionFile = "latest-beta.txt";
	}
	else {
		system("rm -f /data/domains/www.plainblack.com/public/downloads/webgui-latest.tar.gz");
		system("cd /data/domains/www.plainblack.com/public/downloads;ln -s /data/domains/update.webgui.org/public/".$versions[0].".x.x/webgui-".$version.".tar.gz webgui-latest.tar.gz");
	}
	open(FILE,">/data/domains/update.webgui.org/public/".$versionFile);
	print FILE $version;
	close(FILE);
}

#sub publishToSf {
#	print "Publishing version ".$version." to the Source Forge FTP server.\n\nUsername:";
#	my $username = <>;
#	chomp $username;
#	return unless $username;
#	my ($number, $status) = split /-/, $version;
#	my $new_dir = sprintf "%s (%s)", $number, $status;
#	system('lftp -e "cd /home/pfs/project/p/pb/pbwebgui/WebGUI Source; mkdir '.$new_dir.'; cd '.$new_dir.'; put -O uploads '.$buildDir.'/'.$version.'/webgui-'.$version.'.tar.gz; exit" sftp://'.$username.',pbwebgui@frs.sf.net');
#}

sub publishToSf {
	print "Publishing version ".$version." to the Source Forge FTP server.\n\nUsername:";
	my $username = <>;
	chomp $username;
	return unless $username;
	my ($number, $status) = split /-/, $version;
	my $new_dir = sprintf "%s (%s)", $number, $status;
	open my $SFTP, "| sftp $username,pbwebgui\@frs.sf.net" or
		die "Unable to open pipe to sftp: $!";
	print $SFTP qq|cd "/home/pfs/project/p/pb/pbwebgui/WebGUI Source"\n|;
	print $SFTP qq|mkdir "$new_dir"\n|;
	print $SFTP qq|chdir "$new_dir"\n|;
	print $SFTP qq|put $buildDir/$version/webgui-$version.tar.gz webgui-$version.tar.gz\n|;
	print $SFTP qq|exit|;
	close $SFTP;
}

