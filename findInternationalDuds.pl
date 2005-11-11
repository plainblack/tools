#!/usr/bin/perl


# Copyright 2003 Plain Black LLC
# Licensed under the GNU GPL - http://www.gnu.org/licenses/gpl.html 


use lib '/data/WebGUI/lib';
use strict;
use WebGUI::DateTime;
use WebGUI::Session;
use WebGUI::SQL;

my ($sth, $key, $status,%data);

WebGUI::Session::open("/data/WebGUI","WebGUI.conf");
print "# Depricated Language Export\n";
my $sth1 = WebGUI::SQL->read("select * from language where languageId<>1");
while (my %language = $sth1->hash) {
	my %list = ();
	print "\n# ".$language{language}."\n";
        $sth = WebGUI::SQL->read("select * from international where languageId=".$language{languageId});
        while (%data = $sth->hash) {
                $list{"z-".$data{namespace}."-".$data{internationalId}}{id} = $data{internationalId};
                $list{"z-".$data{namespace}."-".$data{internationalId}}{namespace} = $data{namespace};
                $list{"z-".$data{namespace}."-".$data{internationalId}}{lastUpdated} = $data{lastUpdated};
                $list{"z-".$data{namespace}."-".$data{internationalId}}{status} = "deleted";
        }
        $sth->finish;
       	$sth = WebGUI::SQL->read("select * from international where languageId=1");
       	while (%data = $sth->hash) {
		$key = $data{namespace}."-".$data{internationalId};
               	unless ($list{"z-".$key}) {
                       	$list{"a-".$key}{namespace} = $data{namespace};
                       	$list{"a-".$key}{id} = $data{internationalId};
                       	$list{"a-".$key}{status} = "missing";
               	} else {
			if ($list{"z-".$key}{lastUpdated} < $data{lastUpdated}) {
                       		$list{"o-".$key} = $list{"z-".$key};
				delete($list{"z-".$key});
                       		$list{"o-".$key}{status} = "updated";
			} else {
                       		$list{"q-".$key} = $list{"z-".$key};
				delete($list{"z-".$key});
                       		$list{"q-".$key}{status} = "ok";
			}
		}
        }
       	$sth->finish;
        foreach $key (sort {$a cmp $b} keys %list) {
		if ($list{$key}{status} eq "deleted") {
			print "delete from international where languageId=".$language{languageId}." and namespace=".quote($list{$key}{namespace})." and internationalId=".$list{$key}{id}.";\n";
		}
        }
}
$sth1->finish;




