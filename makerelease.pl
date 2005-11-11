#!/usr/bin/perl 


# Copyright 2001-2004 Plain Black LLC
# Licensed under the GNU GPL - http://www.gnu.org/licenses/gpl.html

use Parse::PlainConfig;
use Getopt::Long;
use File::Find;
use File::Path;
use POSIX;

our $version = "";
our $buildDir = "/data/builds";
our $generateCreateScript;
our $mysql = "/usr/bin/mysql";
our $mysqldump = "/usr/bin/mysqldump";
our $mysqluser = "webguibuild";
our $mysqlpass = "webguibuild";
our $mysqldb = "webguibuild";
our $perl = "/usr/bin/perl";
our $branch = "";

GetOptions(
	'version=s'=>\$version,
	'buildDir=s'=>\$buildDir,
	'makedocs=s'=>\$makedocs,
	'generateCreateScript'=>\$generateCreateScript,
	'mysql=s'=>\$mysql,
	'mysqldump=s'=>\$mysqldump,
	'mysqluser=s'=>\$mysqluser,
	'mysqlpass=s'=>\$mysqlpass,
	'mysqldb=s'=>\$mysqldb,
	'perl=s'=>\$perl,
	'branch=s'=>\$branch
	);


if ($version ne "") {
	createDirectory();
	CVSexport();
	generateCreateScript();
	removeUnnecessaryFiles();
	system("mkdir ".$buildDir."/".$version."/WebGUI/www/uploads");
	createTarGz();
} else {
	print <<STOP;
	Usage: $0 --version=0.0.0

	Options:

	--branch		Specify a branch tag to check out from. Defaultly checks out from HEAD.

	--buildDir		The base directory to create all builds in. Defaults to /data/builds.

	--generateCreateScript	If specified a create script will be generated at build time by applying
				all of the upgrades to "previousVersion.sql".

	--makedocs		The path to the makedocs script. Defaults to /data/tools/makedocs.pl.

	--mysql			The path to the mysql client. Defaults to /usr/bin/mysql.

	--mysqldb		The database to use to generate a create script. Defaults to webguibuild.

	--mysqldump		The path to the mysqldump client. Defaults to /usr/bin/mysqldump.

	--mysqlpass		The password for the mysql user. Defaults to webguibuild.

	--mysqluser		A user with administrative privileges for mysql. Defaults to webguibuild.

	--perl			The path to the perl executable. Defaults to /usr/bin/perl.

	--version		The build version. Used to create folders and filenames.

STOP
}

sub generateCreateScript {
	return unless ($generateCreateScript);
	print "Generating create script.\n";
        my $config = Parse::PlainConfig->new('DELIM' => '=', 'FILE' => $buildDir."/".$version.'/WebGUI/etc/WebGUI.conf.original', 'PURGE' => 1);
	$config->set(dsn=>"DBI:mysql:".$mysqldb, dbuser=>$mysqluser, dbpass=>$mysqlpass);
        $config->write($buildDir."/".$version.'/WebGUI/etc/webguibuild.conf');
	my $auth = " -u".$mysqluser;
	$auth .= " -p".$mysqlpass if ($mysqlpass);
	system($mysql.$auth.' -e "create database '.$mysqldb.'"');
	system($mysql.$auth.' --database='.$mysqldb.' < '.$buildDir."/".$version.'/WebGUI/docs/previousVersion.sql');
	system("cd ".$buildDir."/".$version.'/WebGUI/sbin;'.$perl." upgrade.pl --doit");
	system($mysqldump.$auth.' '.$mysqldb.' > '.$buildDir."/".$version.'/WebGUI/docs/create.sql');
	system($mysql.$auth.' -e "drop database '.$mysqldb.'"');
	unlink($buildDir."/".$version.'/WebGUI/etc/webguibuild.conf');
}


sub removeUnnecessaryFiles {
	print "Removing unnecessary files from the distribution.\n";
	unlink($buildDir."/".$version."/WebGUI/docs/previousVersion.sql");
	unlink($buildDir."/".$version."/WebGUI/docs/upgrades/upgrade_0.*");
	unlink($buildDir."/".$version."/WebGUI/docs/upgrades/upgrade_1.*");
	unlink($buildDir."/".$version."/WebGUI/docs/upgrades/upgrade_2.*");
	print "Finished removing.\n";
}

sub createDirectory {
	print "Creating build folder.\n";
	unless (system("mkdir -p ".$buildDir."/".$version)) {
		print "Folder created.\n";
	} else {
		print "Couldn't create folder.\n";
		exit;
	}
}

sub CVSexport {
	print "Exporting latest version.\n";
	my $cmd = "cd ".$buildDir."/".$version."; cvs export -D now ";
	$cmd .= "-r ".$branch if ($branch);
	$cmd .= " WebGUI";
	unless (system($cmd)) {
		print "Export complete.\n";
	} else {
		print "Can't connect to repository.\n";
		exit;
	}
}

sub createTarGz {
        print "Creating webgui-".$version.".tar.gz distribution.\n";
        unless (system("cd ".$buildDir."/".$version."; tar cfz webgui-".$version.".tar.gz WebGUI")) {
                print "File created.\n";
        } else {
                print "Couldn't create file.\n";
		exit;
        }
}

