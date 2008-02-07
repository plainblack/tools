#!/usr/bin/perl

use strict;

$|=1;


use File::Find;

find(\&replaceCopyright, '/data/WebGUI');

sub replaceCopyright {
	my $extension = lc($_);
        $extension =~ s/.*\.(.*?)$/$1/;
	if (isIn($extension, qw(txt pl pm skeleton css html js t))) {
		print "Processing ".$File::Find::name."\n";
		my $file = readFile($File::Find::name);
#print $file;
		$file =~ s/Copyright\s+2001-20\d\d\s+Plain\s+Black/Copyright 2001-2008 Plain Black/ixsg;
#print "\n/////////////////////\n";
#print $file;
		writeFile($File::Find::name,$file);
#exit;
	}	
}

sub isIn {
        my $key = shift;
        $_ eq $key and return 1 for @_;
        return 0;
}

sub readFile {	
	my $file = shift;
	my $contents;
	open(FILE,$file);
	while (<FILE>) {
		$contents .= $_;
	}
	close(FILE);	
	return $contents;
}

sub writeFile {
	my $file = shift;
	my $contents = shift;
	open(FILE,">".$file);
	print FILE $contents;
	close(FILE);	
}	
