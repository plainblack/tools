use lib "/data/WebGUI/lib";
use WebGUI::Session;
use WebGUI::SQL;
use File::Path;

WebGUI::Session::open("/data/WebGUI","www.plainblack.com.conf");

my $nestPoint = -1;

traverse("-1","-2");
rmtree("/tmp/FileCache/Navigation-www.plainblack.com.conf");

WebGUI::Session::close();


sub traverse {
	my $parentId = shift;
	my $depth = shift;
	$depth++;
	my $sth = WebGUI::SQL->read("select pageId from page where parentId=".quote($parentId)." order by sequenceNumber");
	while (my ($pageId) = $sth->array) {
		print " " for (1..$depth);
		print $pageId."\n";
		$nestPoint++;
		WebGUI::SQL->write("update page set depth=$depth, nestedSetLeft=".quote($nestPoint)." where pageId=".quote($pageId));
		traverse($pageId,$depth);
		$nestPoint++;
		WebGUI::SQL->write("update page set nestedSetRight=".quote($nestPoint)." where pageId=".quote($pageId));
	}
	$sth->finish;
}
