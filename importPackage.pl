#!/data/wre/prereqs/bin/perl
use lib "/data/WebGUI/lib";
use strict;

use Getopt::Long;
use WebGUI::Session;
use WebGUI::Asset;
use WebGUI::Asset::Template;
use WebGUI::VersionTag;
use WebGUI::Asset::Wobject::Collaboration;


my ($configFiles,$configFile,$allSites,$parentUrl,$packageFile,$webguiPath);
my $session = start();
for my $key(keys %$configFiles){
    if($allSites || $key eq $configFile){
        addPackage($key);
    }
}

#-------------------------------------------------
sub addPackage {
    my $config = shift;

    print "working on $config .. ";

    my $session = WebGUI::Session->open($webguiPath,$config);

    $session->user({userId=>3});

    my $package = WebGUI::Storage->createTemp( $session );
    $package->addFileFromFilesystem( $packageFile );

    my $versionTag = WebGUI::VersionTag->getWorking($session);

    if(defined $parentUrl){
        $versionTag->set({name => "Adding package to $parentUrl"});
        print " adding to $parentUrl .. ";
        my $asset = WebGUI::Asset->newByUrl($session, $parentUrl);
        die "Encountered problems getting asset at $parentUrl" unless defined $asset;
        $asset->importPackage($package);
    }else{
        print " adding to importNode .. ";
        $versionTag->set({name => "Adding package to importNode"});
        WebGUI::Asset->getImportNode( $session )->importPackage( $package);
    }

    $versionTag->commit;

    $session->var->end;
    $session->close;

    print "finished\n";
}

#-------------------------------------------------
sub usage {
    print <<USAGE;
        Usage: $0 [ --allsites | --config-file=... ] [ --parent-url=... ] [ --webgui-path= ] <package file>
USAGE
    exit 1;
}

#-------------------------------------------------
sub start {
    $| = 1; #disable output buffering
    GetOptions(
        'allsites'    => \$allSites,
        'config-file=s'  => \$configFile,
        'parent-url=s'  => \$parentUrl,
        'webgui-path=s' => \$webguiPath,
    );

    $packageFile = $ARGV[0]; 
    $webguiPath = "/data/WebGUI" if(! defined $webguiPath);

    if((!defined $allSites && !defined $configFile) || !defined $packageFile) {
        usage();
    }
    $configFiles = WebGUI::Config->readAllConfigs($webguiPath);

}

