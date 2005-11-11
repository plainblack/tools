#!/usr/bin/perl

use lib "/data/WebGUI/lib";
use Getopt::Long;
use Parse::PlainConfig;
use strict;
use WebGUI::Session;
use WebGUI::SQL;


my $configFile;
my $quiet;

GetOptions(
        'configFile=s'=>\$configFile,
'quiet'=>\$quiet
);

WebGUI::Session::open("/data/WebGUI",$configFile);


print "\tConverting page tree to the Nested Set model.\n";
sub walk_down {
my($pageId, $o) = @_[0,1];

my $callback = $o->{callback};
my $callbackback = $o->{callbackback};
my $callback_status = 1;

$callback_status = &{ $callback }( $pageId, $o ) if $callback;
if($callback_status) {
# Keep recursing unless callback returned false... and if there's
# anything to recurse into, of course.
my @daughters = WebGUI::SQL->buildArray("select pageId from page where parentId=$pageId and pageId != 0 order by lft");
if(@daughters) {
$o->{'_depth'} += 1;
foreach my $one (@daughters) {
walk_down($one, $o);
}
$o->{'_depth'} -= 1;
}
if($callbackback){
scalar( &{ $callbackback }( $pageId, $o ) );
}
}
return;
}

my $counter = 0;

walk_down(0, {
callback => sub {
WebGUI::SQL->write("update page set depth=".($_[1]->{_depth}-1).", lft=$counter where pageId=".$_[0]);
$counter++;
return 1;
},
callbackback => sub {
WebGUI::SQL->write("update page set rgt=$counter where pageId=".$_[0]);
$counter++;
return 1;
}
});


WebGUI::Session::close();
