#!/data/wre/prereqs/perl/bin/perl

# Copyright 2001-2005 Plain Black Corporation
# Licensed under the GNU GPL - http://www.gnu.org/licenses/gpl.html

use JSON;
use Getopt::Long;
use File::Find;
use File::Path;
use POSIX;

our $version = "";
our $buildDir = "/data/builds";
our $generateCreateScript;
our $mysql = "/data/wre/prereqs/mysql/bin/mysql";
our $mysqldump = "/data/wre/prereqs/mysql/bin/mysqldump";
our $mysqluser = "webguibuild";
our $mysqlpass = "webguibuild";
our $mysqldb = "webguibuild";
our $perl = "/data/wre/prereqs/perl/bin/perl";
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
	SVNexport();
	generateCreateScript();
	createTarGz();
} else {
	print <<STOP;
	Usage: $0 --version=0.0.0

	Options:

	--branch		Specify a branch to check out from (like WebGUI_6.8). Defaultly checks out from HEAD.

	--buildDir		The base directory to create all builds in. Defaults to $buildDir.

	--generateCreateScript	If specified a create script will be generated at build time by applying
				all of the upgrades to "previousVersion.sql".

	--makedocs		The path to the makedocs script. Defaults to $makedocs.

	--mysql			The path to the mysql client. Defaults to $mysql.

	--mysqldb		The database to use to generate a create script. Defaults to $mysqldb.

	--mysqldump		The path to the mysqldump client. Defaults to $mysqldump.

	--mysqlpass		The password for the mysql user. Defaults to $mysqluser.

	--mysqluser		A user with administrative privileges for mysql. Defaults to $mysqlpass.

	--perl			The path to the perl executable. Defaults to $perl.

	--version		The build version. Used to create folders and filenames.

STOP
}

sub generateCreateScript {
	return unless ($generateCreateScript);
	print "Generating create script.\n";
	my $fileContents;
	open(FILE,"<".$buildDir."/".$version.'/WebGUI/etc/WebGUI.conf.original');
	while (<FILE>) {
		$fileContents .= $_ unless ($_ =~ /^\#/);
	}	
	close(FILE);
	my $config = jsonToObj($fileContents);
	$config->{dsn} = "DBI:mysql:".$mysqldb.";host=localhost";
	$config->{dbuser} = $mysqluser;
	$config->{dbpass} = $mysqlpass;
	open(FILE, ">".$buildDir."/".$version.'/WebGUI/etc/webguibuild.conf');
	print FILE "# config-file-type: JSON 1\n".objToJson($config);
	close(FILE);
	my $auth = " -u".$mysqluser;
	$auth .= " -p".$mysqlpass if ($mysqlpass);
	system($mysql.$auth.' -e "create database '.$mysqldb.'"');
	system($mysql.$auth.' --database='.$mysqldb.' < '.$buildDir."/".$version.'/WebGUI/docs/previousVersion.sql');
	system('cp '.$buildDir."/".$version.'/WebGUI/etc/log.conf.original '.$buildDir."/".$version.'/WebGUI/etc/log.conf');
	system("cd ".$buildDir."/".$version.'/WebGUI/sbin;'.$perl." upgrade.pl --doit --mysql=$mysql --mysqldump=$mysqldump --skipBackup");
	system($mysqldump.$auth.' --compact '.$mysqldb.' > '.$buildDir."/".$version.'/WebGUI/docs/create.sql');
	my $cmd = 'cd '.$buildDir."/".$version.'/WebGUI/sbin; /data/wre/prereqs/perl/bin/perl testCodebase.pl --configFile=webguibuild.conf >> /tmp/test.log 2>> /tmp/test.log';
	system($cmd);
	$message = "To: smoketest\@plainblack.com\n";
	$message .= "From: jt\@plainblack.com\n";
	$message .= "Subject: Smoke Test Results\n";
	$message .= "\n";
	open(FILE,"</tmp/test.log");
	while (<FILE>) {
		$message .= $_;
	}
	close(FILE);
	if (open(MAIL,"| /usr/lib/sendmail -t -oi")) {
		print MAIL $message;
		close(MAIL);
	}
	system($mysql.$auth.' -e "drop database '.$mysqldb.'"');
	unlink($buildDir."/".$version.'/WebGUI/etc/webguibuild.conf');
	unlink($buildDir."/".$version.'/WebGUI/etc/log.conf');
	unlink('/tmp/test.log');
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

sub SVNexport {
	print "Exporting latest version.\n";
	my $cmd = "cd ".$buildDir."/".$version."; svn export ";
	if ($branch) {
		$cmd .= "https://svn.webgui.org/svnroot/branch/".$branch;
	} else {
		$cmd .= " https://svn.webgui.org/svnroot/WebGUI";
	}
	unless (system($cmd)) {
		print "Export complete.\n";
		system("cd ".$buildDir."/".$version.";mv ".$branch." WebGUI") if ($branch);
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

