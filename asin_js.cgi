#!/usr/bin/perl
BEGIN {
  unshift @INC, './extlib';
}
use strict;
use CGI;
use Jcode;
use Text::Sukeroku::HTMLElement;
use Text::Sukeroku::Kiseru;

my $cgi  = new CGI;
my $enc  = ($cgi->param('enc')) ? $cgi->param('enc') : 'utf8';
my $asin = $cgi->param('asin');
if(!$asin){
  if($cgi->path_info() =~ /\/asin\/(\w+)\//ig){
    $asin = $1;
  }
  else{
    $asin = '';
  }
}
my $result = "";
if($asin ne ''){
  my $config = Text::Sukeroku::Kiseru->new();
  my $html   = Text::Sukeroku::HTMLElement->new({
    config => $config,
  });
  $result = $html->asinDetail($asin);
}
else{
  $result = "Not Found ASIN Code.";
}
print "Content-type: text/javascript\n\n";
foreach my $line(split(/\n/, $result)){
  $line =~ s|\'|\\\'|g;
  $line = qq(document.write\('${line}'\);\n);
  if($enc ne 'utf8'){
    $line = Jcode::convert($line, $enc);
  }
  print $line;
}
exit 0;
