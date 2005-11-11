#!/usr/bin/perl -w

my $dsn = "DBI:mysql:dev";
my $user = "webgui";
my $pass = "password";
my $pathToExport = "/tmp/";

#---no need to edit beyond here---------------------

use DBI;
use strict;

my $dbh = DBI->connect($dsn,$user,$pass);
fixes($dbh);
exportLanguages($dbh,$pathToExport);
exportHelp($dbh,$pathToExport);
$dbh->disconnect;

sub fixes {
	my $dbh = shift;
	# quickly fix some quirky stuff
	$dbh->do("delete from help where helpId in (9,16) and namespace='WebGUI'");
	$dbh->do("alter table international change internationalId internationalId varchar(255) not null");
	my $sth = $dbh->prepare("select internationalId,namespace from international where namespace like 'Auth%'");
	$sth->execute;
	while (my $data = $sth->fetchrow_hashref) {
		if ($data->{namespace} =~ /Auth\/(\w+)\/(\w+)/) {
			$dbh->do("update international set internationalId=".$dbh->quote(lc($2).'-'.$data->{internationalId}).", 
				namespace=".$dbh->quote('Auth/'.$1)." where internationalId="
				.$data->{internationalId}." and namespace=".$dbh->quote($data->{namespace}));
		}
	}
	$sth->finish;
	$dbh->do("alter table help change bodyId bodyId varchar(255) not null");
	$dbh->do("alter table help change titleId titleId varchar(255) not null");
	$dbh->do("alter table help change helpId helpId varchar(255) not null");
	$sth = $dbh->prepare("select * from help where namespace like 'Auth%'");
	$sth->execute;
	while (my $data = $sth->fetchrow_hashref) {
		my $hid = $data->{helpId};
		my $ns = $data->{namespace};
		if ($data->{namespace} =~ /Auth\/(\w+)\/(\w+)/) {
			$data->{namespace} = "Auth/".$1;
			$data->{titleId} = lc($2).'-'.$data->{titleId};
			$data->{bodyId} = lc($2).'-'.$data->{bodyId};
			$data->{helpId} = lc($2).'-'.$data->{helpId};
		}
		my @related = split(";",$data->{seeAlso});
		my @newrelated;
		foreach my $pair (@related) {
			my ($id,$namespace) = split(",",$pair);
			if ($namespace =~ /Auth\/(\w+)\/(\w+)/) {
				$namespace = "Auth/".$1;
				$id = lc($2).'-'.$id;
			}
			push(@newrelated,join(",",$id,$namespace));
		}
		$data->{seeAlso} = join(";",@newrelated);
		$dbh->do("update help set helpId=".$dbh->quote($data->{helpId}).", namespace=".$dbh->quote($data->{namespace}).", titleId=".$dbh->quote($data->{titleId}).",
			bodyId=".$dbh->quote($data->{bodyId}).", seeAlso=".$dbh->quote($data->{seeAlso})." where helpId=".$hid." and namespace=".$dbh->quote($ns));
	}
	$sth->finish;
}

sub exportHelp {
	my $dbh = shift;
	my $defaultPath = shift;
	my $sth = $dbh->prepare("select distinct(namespace) from help");
	$sth->execute;
	while (my ($namespace) = $sth->fetchrow_array) {
		my $newNamespace = fixNamespace($namespace);
		my $content = "package WebGUI::Help::".$newNamespace.";\n\n";;
		$content .= 'our $HELP = {'."\n";
		my $sth2 = $dbh->prepare("select * from help where namespace=".$dbh->quote($namespace));
		$sth2->execute;
		while (my $data = $sth2->fetchrow_hashref) {
			$content .= "\t'".createTag($dbh,$data->{titleId},$namespace)."' => {\n";
			$content .= "\t\ttitle => '".$data->{titleId}."',\n";
			$content .= "\t\tbody => '".$data->{bodyId}."',\n";
			$content .= "\t\trelated => [\n";
			my @seealso = split(";",$data->{seeAlso});
			my @rel;
			foreach my $related (@seealso) {
				my @pair = split(",",$related);
				my $temp = "\t\t\t{\n";
				my $sth3 = $dbh->prepare("select titleId from help where helpId=".$pair[0]." and namespace=".$dbh->quote($pair[1]));
				$sth3->execute;
				my ($id) = $sth3->fetchrow_array;
				$sth3->finish;
				$temp .= "\t\t\t\ttag => '".createTag($dbh,$id,$pair[1])."',\n";
				$temp .= "\t\t\t\tnamespace => '".fixNamespace($pair[1])."'\n";
				$temp .= "\t\t\t}";
				push(@rel,$temp);
			}
			$content .= join(",\n",@rel)."\n" if (scalar(@rel));
			$content .= "\t\t]\n";
			$content .= "\t},\n";
		}
		$sth2->finish;
		$content .= "};\n";
		$content .= "\n1;\n";
		writeFile($defaultPath."/Help/".$newNamespace.".pm",$content);
	}
	$sth->finish;
}

sub createTag  {
	my $dbh = shift;
	my $id = shift;
	my $namespace = shift;
	my $tag = getInternationalValue($dbh,$id,$namespace);
	$tag = "missing" unless ($tag);
	$tag =~ s/\"//g;
	$tag =~ s/\'//g;
	$tag =~ s/\,//g;
	$tag =~ s/\)//g;
	$tag =~ s/\(//g;
	return lc($tag);
}

sub fixNamespace {
	my $namespace = shift;
	$namespace =~ s/ //g;
	$namespace =~ s/\///g;
	return $namespace;
}

sub getInternationalValue {
	my $dbh = shift;
	my $id = shift;
	my $namespace = shift;
	my $sth = $dbh->prepare("select message from international where internationalId=".$dbh->quote($id)." and namespace=".$dbh->quote($namespace)." and languageId=1");
	$sth->execute;
	my ($msg) = $sth->fetchrow_array;
	$sth->finish;
	return $msg;
}

sub exportLanguages {
	my $dbh = shift;
	my $defaultPath = shift;
	my $sth = $dbh->prepare("select * from language");
	$sth->execute;
	while (my $data = $sth->fetchrow_hashref) {
	print $data->{language}."\n";
		my $lang = findLangName($data->{language});
		my $content = "package WebGUI::i18n::".$lang.";\n\n";
		$content .= 'our $LANGUAGE = {'."\n";
		$content .= "\t".'label => "'.$data->{language}.'",'."\n";
		$content .= "\t".'charset => "'.$data->{characterSet}.'",'."\n";
		$content .= "\t".'toolbar => "'.$data->{toolbar}.'"'."\n";
		$content .= '};'."\n";
		$content .= "\n1;\n";
		writeFile($defaultPath."/i18n/".$lang.".pm",$content);
		exportNamespaces($dbh, $defaultPath."/i18n", $data->{languageId}, $lang);
	}
	$sth->finish;
}

sub exportNamespaces {
	my $dbh = shift;
	my $defaultPath = shift;
	my $langId = shift;
	my $lang = shift;
	my $sth = $dbh->prepare("select distinct(namespace) from international where languageId=".$langId);
	$sth->execute;
	while (my ($namespace) = $sth->fetchrow_array) {
		my $newNamespace = fixNamespace($namespace);
		my $content = "package WebGUI::i18n::".$lang."::".$newNamespace.";\n\n";
		$content .= 'our $I18N = {'."\n";
		my $sth2 = $dbh->prepare("select * from international where languageId=".$langId." and namespace=".$dbh->quote($namespace));
		$sth2->execute;
		while (my $data = $sth2->fetchrow_hashref) {
			$data->{message} =~ s/\|/\\\|/g;
			$content .= "\t'".$data->{internationalId}."' => {\n";
			$content .= "\t\tmessage => ".'q|'.$data->{message}."|,\n";
			$content .= "\t\tlastUpdated => ".$data->{lastUpdated};
			$content .= ",\n\t\tcontext => ".'q|'.$data->{context}."|" if ($data->{context});
			$content .= "\n\t},\n\n";
		}
		$sth2->finish;
		$content .= '};'."\n";
		$content .= "\n1;\n";
		writeFile($defaultPath."/".$lang."/".$newNamespace.".pm",$content);
	}
	$sth->finish;
}

sub findLangName {
	my $lang = shift;
	if ($lang =~ /\(/) {
		$lang =~ s/.*?\((.*?)\)/$1/g;
	}
	$lang =~ s/\s//g;
	return $lang;
}

sub writeFile {
	my $filepath = shift;
	my $content = shift;
	my $mkdir = substr($filepath,1,(length($filepath)-1));
	my @path = split("\/",$mkdir);
	$mkdir = "";
	foreach my $part (@path) {
		next if ($part =~ /\.pm/);
		$mkdir .= "/".$part;
		mkdir($mkdir);
	}
	open(FILE,">".$filepath);
	print FILE $content;
	close(FILE);
}

