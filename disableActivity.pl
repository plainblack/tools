#!/data/wre/prereqs/bin/perl
use lib "/data/WebGUI/lib";
use strict;

our $VERSION = "0.0.1";

use Getopt::Long;
use WebGUI::Session;
use WebGUI::Asset;
use WebGUI::VersionTag;

my ($configFiles,$configFile,$allSites,$activityIds,$webguiPath,$id,$title);
my $session = start();
for my $key(keys %$configFiles){
    if($allSites || $key eq $configFile){
        removeActivities($key);
    }
}

#-------------------------------------------------
sub removeActivities {
    my $config = shift;

    print "working on $config .. \n";

    my $session = WebGUI::Session->open($webguiPath,$config);
    $session->user({userId=>3});
    
    if(defined $id){push(@$activityIds,$id);}
    if(defined $title){
        my @ids = $session->db->buildArray('select activityId from WorkflowActivity where title = ?',[$title]);
        push(@$activityIds,@ids);
    }

    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->set({name => "Disabling activies ".join(',',@$activityIds)});
   

    for my $a(@$activityIds){ 
        my $wid = $session->db->quickScalar("select workflowId from WorkflowActivity where activityId = ?",[$a]);
        my $workflow = WebGUI::Workflow->new($session, $wid);
        if (defined $workflow) {
            $workflow->deleteActivity($a);
        }
    }
    $versionTag->commit;
    $session->var->end;
    $session->close;

    print "finished\n";
}

#-------------------------------------------------
sub usage {
    print <<USAGE;
        Usage: $0 [ --allsites | --config-file=... ] [ --webgui-path=...] --activityId=... | --title=... 
USAGE
    exit 1;
}

#-------------------------------------------------
sub start {
    $| = 1; #disable output buffering
    GetOptions(
        'allsites'      => \$allSites,
        'config-file=s' => \$configFile,
        'activityId=s'  => \$id,
        'title=s'       => \$title,
        'webgui-path=s' => \$webguiPath,
    );

    $webguiPath = "/data/WebGUI" if(! defined $webguiPath);

    if((!defined $title && !defined $id)) {
        usage();
    }
   

    $configFiles = WebGUI::Config->readAllConfigs($webguiPath);

}

