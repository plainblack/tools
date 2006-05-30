#!/usr/bin/perl 


# Copyright 2001-2003 Plain Black LLC
# Licensed under the GNU GPL - http://www.gnu.org/licenses/gpl.html

use Parse::PlainConfig;
use Getopt::Long;
use File::Find;
use File::Path;
use POSIX;

our $version = "";
our $buildDir = "/data/builds";
our $pod2html = "/usr/bin/pod2html";

GetOptions(
	'version=s'=>\$version,
	'buildDir=s'=>\$buildDir,
	'pod2html=s'=>\$pod2html
	);


if ($version ne "") {
	buildFromDir();
} else {
	print <<STOP;
	Usage: $0 --version=0.0.0

	Options:

	--buildDir		The base directory to create all builds in. Defaults to /data/builds.

	--pod2html		The path to the pod2html script. Defaults to /usr/bin/pod2html.

	--version		The build version. Used to create folders and filenames.

STOP
}


sub buildFromDir {
	my $dir = $_[0];
	my $basedir = $buildDir."/".$version."/WebGUI/lib/WebGUI";
        opendir(DIR,$basedir."/".$dir);
        my @files = readdir(DIR);
        closedir(DIR);
        @files = sort @files;
	my $first = 1;
        foreach my $file (@files) {
                if ($file =~ /(.*?)\.pm$/ && $file ne "Operation.pm") {
			if ($first) {
				print "Making API docs directory: ".$buildDir."/".$version."/api/".$dir."\n";
				system("mkdir -p ".$buildDir."/".$version."/api/".$dir);
				$first = 0;
			}
			$outfile = $buildDir."/".$version."/api/".$dir."/".$1.".html";
                        print "Generating docs for ".$basedir."/".$dir."/".$file."\n";
                        system($pod2html." --quiet --css http://files.plainblack.com/downloads/builds/api.css --noindex ".$basedir."/".$dir."/".$file." > ".$outfile);
		#	filterContent($outfile);
                } elsif ($file ne "." && $file ne "..") {
                        buildFromDir($dir."/".$file);
                }
        }
}

sub filterContent {
	my $file = $_[0];
	print "Filtering content for ".$file."\n";
	open(FILE,"<".$file);
	my $content;
	while (<FILE>) {
		$content .= $_;
	}
	close(FILE);

	$content =~ s/NOTE:/<b>NOTE:<\/b>/ig;
	$content =~ s/TIP:/<b>TIP:<\/b>/ig;
	$content =~ s/<a .*?>//ig;
	$content =~ s/<\/a>//ig;
	$content =~ s/<hr>//ig;
	$content =~ s/<head>(.*?)<\/head>//ixsg;

	$pattern = 'INDEX BEGIN.*?INDEX END';
	$content =~ s/$pattern//isg;
                                                                                                                                                             
	$content =~ s/SYNOPSIS/Synopsis/g;
	$content =~ s/DESCRIPTION/Description/g;
	$content =~ s/METHODS/Methods/g;
                                                                                                                                                             
                                                                                                                                                             
#	$pattern = '<h1>DESCRIPTION<\/h1>
#<P>(.*?)<\/P>
#<P>';
#	$content =~ s/$pattern/$1<p>/isg;
                                                                                                                                                             
                                                                                                                                                             
#	$content =~ s/<h2>/<h4 style="font-family: Arial;font-size: 10pt;font-style: italic; font-weight: bold;">/ig;
#	$content =~ s/<\/h2>/<\/h4>/ig;
                                                                                                                                                             
                                                                                                                                                             
#	$pattern = '<h1>NAME<\/h1>
#<P>Package .*?::(.*?)<\/P>
#<P>';
#	$content =~ s/$pattern/<br><br><h2 style="font-family: Arial;font-size: 18pt;">$1<\/h2>/isg;
                                                                                                                                                             
                                                                                                                                                             
#	$content =~ s/<h1>/<h3 style="font-family: Arial;font-size: 14pt;">/ig;
#	$content =~ s/<\/h1>/<\/h3>/ig;
                                                                                                                                                             
                                                                                                                                                             
	$pattern = '<DT><STRONG>(.*?)<\/STRONG><BR>';
	$content =~ s/$pattern/<dt><span style="font-family: Arial;font-style: italic;">$1<\/span>/ig;
                                                                                                                                                             
	$content =~ s/<pre>/<pre style="font-family: courier,courier new,fixed;">/ig;
                                                                                                                                                             
	$content =~ s/<\!--  -->//gi;


	open(FILE,">".$file);
	print FILE $content;
	close(FILE);
}
