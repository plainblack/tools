#!/data/wre/prereqs/bin/perl
use lib "/data/WebGUI/lib";
use strict;

our $VERSION = "0.0.1";

use Getopt::Long;
use WebGUI::Session;
use WebGUI::Asset;
use WebGUI::Asset::Template;
use WebGUI::VersionTag;
use WebGUI::Asset::Wobject::Collaboration;


my ($configFiles,$configFile,$allSites,$updateTime,$webguiPath);
my $session = start();
for my $key(keys %$configFiles){
    if($allSites || $key eq $configFile){
        updateCollaborations($key);
    }
}

#-------------------------------------------------
sub updateCollaborations {
    my $config = shift;

    print "working on $config .. ";

    my $session = WebGUI::Session->open($webguiPath,$config);

    $session->user({userId=>3});

    my $versionTag = WebGUI::VersionTag->getWorking($session);

    my @css = $session->db->buildArray('select a.url from assetData a, Collaboration c where c.assetId = a.assetId');
    my %hcss;
    map($hcss{$_} = 1,@css);
    for my $cs(keys %hcss){
        $versionTag->set({name => "Updating $cs to archive in $updateTime seconds "});
        print $cs,"\n";
        my $asset = WebGUI::Asset->newByUrl($session, $cs);
	    $asset->update({'archiveAfter'=>$updateTime});
        die "Encountered problems getting asset at $cs" unless defined $asset;
    }
    $versionTag->commit;
    $session->var->end;
    $session->close;

    print "finished\n";
}

#-------------------------------------------------
sub usage {
    print <<USAGE;
        Usage: $0 [ --allsites | --config-file=... ] [ --update-time=... ] [ --webgui-path= ] 
USAGE
    exit 1;
}

#-------------------------------------------------
sub start {
    $| = 1; #disable output buffering
    GetOptions(
        'allsites'    => \$allSites,
        'config-file=s'  => \$configFile,
        'update-time=s'  => \$updateTime,
        'webgui-path=s' => \$webguiPath,
    );

    $webguiPath = "/data/WebGUI" if(! defined $webguiPath);

    $updateTime = (defined $updateTime) ? $updateTime : 2147483647;

    if((!defined $allSites && !defined $configFile)) {
        usage();
    }
    $configFiles = WebGUI::Config->readAllConfigs($webguiPath);

}

