#!/data/wre/prereqs/bin/perl
use lib "/data/WebGUI/lib";
use strict;

our $VERSION = "0.0.1";

use Getopt::Long;
use WebGUI::Session;
use WebGUI::Asset;
use WebGUI::VersionTag;
use WebGUI::Asset::Wobject::Collaboration;


my ($configFiles,$configFile,$allSites,$updateTime,$webguiPath);
my $session = start();
for my $key(keys %$configFiles){
    if($allSites || $key eq $configFile){
        updatePosts($key);
    }
}

#-------------------------------------------------
sub updatePosts {
    my $config = shift;

    print "working on $config .. \n";

    my $session = WebGUI::Session->open($webguiPath,$config);

    $session->user({userId=>3});

    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->set({name => "Updating to un-archive posts in the last ".($updateTime/86400) ." days "});

    my @css = $session->db->buildArray('select a.url from assetData a, Collaboration c where c.assetId = a.assetId');
    my %hcss;
    map($hcss{$_} = 1,@css);

    for my $cs(keys %hcss){
        print "\t$cs\n";
        my $asset = WebGUI::Asset->newByUrl($session, $cs);
        next unless defined $asset;
        my $epoch = $session->datetime->time(); 
        my $archiveDate = $epoch - $updateTime;
        my $sql = "select asset.assetId, assetData.revisionDate from Post left join asset on asset.assetId=Post.assetId 
           left join assetData on Post.assetId=assetData.assetId and Post.revisionDate=assetData.revisionDate
           where Post.revisionDate>? and assetData.status='archived' and asset.state='published'
                and Post.threadId=Post.assetId and asset.lineage like ?";
        my $b = $session->db->read($sql,[$archiveDate, $asset->get("lineage").'%']);
        while (my ($id, $version) = $b->array) {
            my $thread = WebGUI::Asset->new($session, $id, "WebGUI::Asset::Post::Thread", $version);
            my $archiveIt = 1;
            foreach my $post (@{$thread->getPosts}) {
                $archiveIt = 0 if (defined $post && $post->get("revisionDate") < $archiveDate);
            }
            $thread->unarchive if ($archiveIt);
        }
        $b->finish;
    }
    $versionTag->commit;
    $session->var->end;
    $session->close;

    print "finished\n";
}

#-------------------------------------------------
sub usage {
    print <<USAGE;
        Usage: $0 [ --allsites | --config-file=... ] [ --time-since=(days before now to dearchive, defaults to 5 years) ] [ --webgui-path= ] 
USAGE
    exit 1;
}

#-------------------------------------------------
sub start {
    $| = 1; #disable output buffering
    GetOptions(
        'allsites'    => \$allSites,
        'config-file=s'  => \$configFile,
        'time-since=s'  => \$updateTime,
        'webgui-path=s' => \$webguiPath,
    );

    $webguiPath = "/data/WebGUI" if(! defined $webguiPath);

    $updateTime = (defined $updateTime) ? ($updateTime*86400) : 157680000;

    if((!defined $allSites && !defined $configFile)) {
        usage();
    }
    $configFiles = WebGUI::Config->readAllConfigs($webguiPath);

}

