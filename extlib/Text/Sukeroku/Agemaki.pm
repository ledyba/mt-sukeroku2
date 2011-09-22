package Text::Sukeroku::Agemaki;
##----------------------------------------------------------------------
## フォーマットファクトリ Agemaki
##----------------------------------------------------------------------
use Text::Sukeroku::BaseFormat;
use Text::Sukeroku::YukiWiki;
use Text::Sukeroku::PukiWiki;
use Text::Sukeroku::HatenaDiary;

use strict;
use Carp qw(croak);

##----------------------------------------------------------------------
## コンストラクタ
##----------------------------------------------------------------------
sub new{
  my $class  = shift;
  my $param  = shift if (@_);
  $param->{dummy}   = '';
  bless $param,$class;
}
##----------------------------------------------------------------------
## ファクトリメソッド
##----------------------------------------------------------------------
sub create{
  my $self   = shift;
  my $format = shift  || croak ('format is not exist!!');
  my $source = shift  || croak ('source is not exist!!');
  my $obj;
  if($format =~ /yukiwiki/i){
    $obj = Text::Sukeroku::YukiWiki->new($source);
  }
  elsif($format =~ /pukiwiki/i){
    $obj = Text::Sukeroku::PukiWiki->new($source);
  }
  elsif($format =~ /hatena/i){
    $obj = Text::Sukeroku::HatenaDiary->new($source);
  }
  return $obj;
}
1;
