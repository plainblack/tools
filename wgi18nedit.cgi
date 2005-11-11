#!/usr/bin/perl

our $outputPath = "/tmp/i18n";
our $languageId = "Dutch";
our $webguiPath = "/data/WebGUI";

#----no need to edit below this line -------------


use strict;
use CGI;
use URI::Escape;


#-----main----------------

$|=1; # disable output buffer
our $cgi = CGI->new;
my $lang = getLanguage();
print $cgi->header(
	-charset=>$lang->{charset}
		);
if ($cgi->param("op") ne "") {
	print header($lang);
	if ($cgi->param("op") =~ /^[A-Za-z]+$/) {
		my $cmd = "&www_".$cgi->param("op");
		print eval($cmd);
	} else {
		print "<h1>Stop Screwing Around</h1>";
	}	
	print footer();
} else {
	print buildSiteFrames();
}

#-----end main------------



sub buildSiteFrames {
	my $output = ' 
<html>
<head><title>WebGUI Internationalization Editor</title></head>
<frameset cols="140,*">
<frame name="menu" src="'.buildURL("displayMenu").'">
<frame name="editor" src="'.buildURL("editLanguage").'">
</frameset>
</html>
';
	return $output;
}

sub buildURL {
	my $op = shift;
	my $params = shift;
	my $url = $ENV{SCRIPT_NAME}.'?op='.$op;
	foreach my $param (keys %{$params}) {
		$url .= '&'.$param.'='.uri_escape($params->{$param});
	}
	return $url;
}

sub fixFormData {
        my $value = shift;
        $value =~ s/\"/\&quot\;/g;
        $value =~ s/\&/\&amp\;/g;
        $value =~ s/\</\&lt\;/g;
        $value =~ s/\>/\&gt\;/g;
        return $value;
}

sub footer {
	return '</body></html>';
}

sub getLanguage {
	my $load = $outputPath.'/'.$languageId.'.pm';
	eval {require $load};
	if ($@) {
		writeLanguage();
		return getLanguage();
	} else {
		my $cmd = "\$WebGUI::i18n::".$languageId."::LANGUAGE";
		return eval ($cmd);
	}
}

sub getNamespaceItems {
	my $namespace = shift;
	my $languageId = shift || "English";
	my $inLoop = shift;
	my $load;
	if ($languageId eq "English") {
		$load = $webguiPath.'/lib/WebGUI/i18n/English/'.$namespace.'.pm';
	} else {
		$load = $outputPath.'/'.$languageId.'/'.$namespace.'.pm';
	}
	eval {require $load};
	if ($@ && !$inLoop) {
		writeNamespace($namespace);
		return getNamespaceItems($namespace,$languageId, 1);
	} else {
		my $cmd = "\$WebGUI::i18n::".$languageId."::".$namespace."::I18N";
		return eval($cmd);
	}
}

sub getNamespaces {
	opendir (DIR,$webguiPath.'/lib/WebGUI/i18n/English/');
       	my @files = readdir(DIR);
       	closedir(DIR);
	@files = sort @files;
	my @namespaces;
       	foreach my $file (@files) {
               	if ($file =~ /(.*?)\.pm$/) {
			push(@namespaces,$1);
               	}
       	}
	return \@namespaces;
}

sub header {
	my $lang = shift;
	return "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=".$lang->{charset}."\" /></head>
<style>
	th {
		text-align: left;
		font-weight: bold;
		font-size: 13px;
		background-color: #f0f0f0;
		font-family: sans, helvetica, arial;
	}
	.outOfDate {
		background-color: #ffaaaa;
		font-weight: bold;
	}
</style><body>";
}

sub preview {
	my $text = shift || "not yet defined";
	$text = substr($text,0,50);
	$text =~ s/&/&amp;/g;
	$text =~ s/\</&lt;/g;
	$text =~ s/\>/&gt;/g;
	return $text;
}

sub setLanguage {
	my $label = shift;
	my $toolbar = shift;
	my $charset = shift;
	my $output = "\tlabel => '".$label."',\n";
	$output .= "\tcharset => '".$charset."',\n";
	$output .= "\ttoolbar => '".$toolbar."'\n";
	writeLanguage($output);
}

sub setNamespaceItems {
	my $namespace = shift;
	my $tag = shift;
	my $message = shift;
	my $eng = getNamespaceItems($namespace);
	my $lang = getNamespaceItems($namespace,$languageId);
	$lang->{$tag}{message} = $message;
	$lang->{$tag}{message} =~ s/\|/\\\|/g;
	$lang->{$tag}{lastUpdated} = time();
	my $output;
	foreach my $tag (keys %{$eng}) {
		$output .= "\t'".$tag."' => {\n";
       	        $output .= "\t\tmessage => ".'q|'.$lang->{$tag}{message}."|,\n";
                $output .= "\t\tlastUpdated => ".$lang->{$tag}{lastUpdated};
                $output .= "\n\t},\n\n";
	}
	writeNamespace($namespace,$output);
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
        if (open(FILE,">".$filepath)) {
        	print FILE $content;
        	close(FILE);
	} else {
		print "ERROR writing file ".$filepath." because ".$1.".\n";
		exit;
	}
}

sub writeLanguage {
	my $data = shift;
	my $output = "package WebGUI::i18n::".$languageId.";\n\n";
	$output .= "\$LANGUAGE = {\n";
	$output .= $data;
	$output .= "};\n\n1;\n";
	writeFile($outputPath.'/'.$languageId.'.pm', $output);
}

sub writeNamespace {
	my $namespace = shift;
	my $data = shift;
	my $output = "package WebGUI::i18n::".$languageId."::".$namespace.";\n\n";
	$output .= "our \$I18N = {\n";
	$output .= $data;
	$output .= "};\n\n1;\n";
	writeFile($outputPath.'/'.$languageId.'/'.$namespace.'.pm', $output);
}

sub www_displayMenu {
	my $output = '<a href="'.buildURL("editLanguage").'" target="editor">'.$languageId.'</a><br><br>';
	my $namespaces = getNamespaces();
	foreach my $namespace (@{$namespaces}) {
		$output .= '<a href="'.buildURL("listItemsInNamespace",{namespace=>$namespace}).'" target="editor">'.$namespace.'</a><br>';
	}
	return $output;
}

sub www_editItem {
	my $eng = getNamespaceItems($cgi->param("namespace"));
	my $lang = getNamespaceItems($cgi->param("namespace"),$languageId);
	my $output = '<form><table>';
	$output .= '<tr><th>Namespace</th><td>'.$cgi->param("namespace").'</td></tr>';
	$output .= '<input type="hidden" name="namespace" value="'.$cgi->param("namespace").'">';
	$output .= '<tr><th>Tag</th><td>'.$cgi->param("tag").'</td></tr>';
	$output .= '<input type="hidden" name="tag" value="'.$cgi->param("tag").'">';
	$output .= '<input type="hidden" name="op" value="editItemSave">';
	$output .= '<tr><th valign="top">Message</td><td><textarea cols="80" rows="30" name="message">'.fixFormData($lang->{$cgi->param("tag")}{message}).'</textarea></td></tr>';
	$output .= '<tr><th></th><td><input type="submit" value="Save"></td></tr>';
	$output .= '<tr><th valign="top">Original Message</th><td>'.$eng->{$cgi->param("tag")}{message}.'</td></tr>';
	$output .= '<tr><th valign="top">Message Context Info</th><td>'.$eng->{$cgi->param("tag")}{context}.'</td></tr>' if ($eng->{$cgi->param("tag")}{context});
	$output .= '</table></form>';
	return $output;
}

sub www_editItemSave {
	setNamespaceItems($cgi->param("namespace"),$cgi->param("tag"),$cgi->param("message"));
	return "Message saved.<p>".www_listItemsInNamespace();
}

sub www_editLanguage {
	my $lang = getLanguage();
	my $output = '<form><table>';
	$output .= '<input type="hidden" name="op" value="editLanguageSave">';
	$output .= '<tr><th>Label</th><td><input type="text" name="label" value="'.$lang->{label}.'"></td></tr>';
	$output .= '<tr><th>Character Set</th><td><input type="text" name="charset" value="'.$lang->{charset}.'"></td></tr>';
	$output .= '<tr><th>Toolbar</th><td><input type="text" name="toolbar" value="'.$lang->{toolbar}.'"></td></tr>';
	$output .= '<tr><th></th><td><input type="submit" value="Save"></td></tr>';
	$output .= '</table></form>';
	return $output;
}

sub www_editLanguageSave {
	setLanguage($cgi->param("label"), $cgi->param("toolbar"), $cgi->param("charset"));
	return "Language saved.<p>".www_editLanguage();
}

sub www_listItemsInNamespace {	
	my $eng = getNamespaceItems($cgi->param("namespace"));
	my $lang = getNamespaceItems($cgi->param("namespace"),$languageId);
	my $output = '<table>';
	foreach my $tag (sort keys %{$eng}) {
		$output .= '<tr';
		if ($eng->{$tag}{lastUpdated} > $lang->{$tag}{lastUpdated}) {
			$output .= ' class="outOfDate"';
		}
		$output .= '><td><a href="'.buildURL("editItem",{namespace=>$cgi->param("namespace"),tag=>$tag}).'">'.$tag.'</a></td><td>';
		if ($lang->{$tag} ne "") {
			$output .= preview($lang->{$tag}{message});
		} else {
			$output .= preview($eng->{$tag}{message});
		}
		$output .= '</td></tr>';
	}
	$output .= '</table>';
	return $output;
}

