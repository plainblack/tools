#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

our ($webguiRoot);

BEGIN {
        $webguiRoot = "/data/WebGUI";
        unshift (@INC, $webguiRoot."/lib");
}

use strict;
use DBI;
use File::Path;
use WebGUI::Config;
use WebGUI::Session;
use WebGUI::Utility;

my $mysql = "mysql";

if (!($^O =~ /^Win/i) && $> != 0 ) {
	print "You must be the super user to use this utility.\n";
	exit;
}

## Globals

$| = 1;
our $perl = $^X;
our $slash;
if ($^O =~ /^Win/i) {
	$slash = "\\";
} else {
	$slash = "/";
}
our %config;


## Find site configs.

print "\nGetting site configs...\n";
my $configs = WebGUI::Config->readAllConfigs($webguiRoot);
foreach my $filename (keys %{$configs}) {
	print "\tProcessing $filename.\n";
	$config{$filename}{configFile} = $filename;
	$config{$filename}{dsn} = $configs->{$filename}->get("dsn");
	my $temp = _parseDSN($config{$filename}{dsn}, ['database', 'host', 'port']);
	if ($temp->{'driver'} eq "mysql") {
		$config{$filename}{db} = $temp->{'database'};
		$config{$filename}{host} = $temp->{'host'};
		$config{$filename}{port} = $temp->{'port'};
		$config{$filename}{dbuser} = $configs->{$filename}->get("dbuser");
		$config{$filename}{dbpass} = $configs->{$filename}->get("dbpass");
		my $session = WebGUI::Session->open($webguiRoot,$filename);
        my @version = $session->db->quickArray("select webguiVersion from webguiVersion order by
        dateApplied desc, length(webguiVersion) desc, webguiVersion desc limit 1");
        my @v = split/\./,$version[0];
        print "Verion $version[0]\n";
        if(!($v[0] >= 7 and $v[1] >= 5 and $v[2] >= 10)){die "Only for installs after 7.5.10\n";}
        correctTransactionItems($session);
        $session->close();
	} else {
		delete $config{$filename};
		print "\tNot for non-MySQL database.\n";
	}
}

sub correctTransactionItems{
    my $session = shift;
    my $db = $session->db;
    print "Deleting bad transactionItems:";
    $db->write("delete from transactionItem where transactionId in (select transactionId from oldtransaction)");
    print " - finished\n";
    my $transactionResults = $db->read("select * from oldtransaction order by initDate");
    while (my $oldTranny = $transactionResults->hashRef) {
        my $date = WebGUI::DateTime->new($session, $oldTranny->{initDate});
        my $itemResults = $db->read("select * from oldtransactionitem where transactionId=?",[$oldTranny->{transactionId}]);
        while (my $oldItem = $itemResults->hashRef) {
            my $status = $oldItem->{shippingStatus};
            $status = 'NotShipped' if $status eq 'NotSent';
            $db->setRow("transactionItem","itemId",{
                itemId                  => "new",
                transactionId           => $oldItem->{transactionId},
                configuredTitle         => $oldItem->{itemName},
                options                 => '{}',
                shippingTrackingNumber  => $oldTranny->{trackingNumber},
                orderStatus             => $oldTranny->{shippingStatus},
                lastUpdated             => $date->toDatabase,
                quantity                => $oldItem->{quantity},
                price                   => $oldItem->{amount},
                vendorId                => "defaultvendor000000000",
            });
        }
    }
}

#-----------------------------------------
sub _parseDSN {
    my($dsn, $args) = @_;
    my($var, $val, $hash);
    $hash = {};

    if (!defined($dsn)) {
        return;
    }

    $dsn =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i
                        or '' =~ /()/; # ensure $1 etc are empty if match fails
    $hash->{driver} = $1;

    while (length($dsn)) {
        if ($dsn =~ /([^:;]*)[:;](.*)/) {
            $val = $1;
            $dsn = $2;
        } else {
            $val = $dsn;
            $dsn = '';
        }
        if ($val =~ /([^=]*)=(.*)/) {
            $var = $1;
            $val = $2;
            if ($var eq 'hostname'  ||  $var eq 'host') {
                $hash->{'host'} = $val;
            } elsif ($var eq 'db'  ||  $var eq 'dbname') {
                $hash->{'database'} = $val;
            } else {
                $hash->{$var} = $val;
            }
        } else {
            foreach $var (@$args) {
                if (!defined($hash->{$var})) {
                    $hash->{$var} = $val;
                    last;
                }
            }
        }

     }
     return $hash;
}

