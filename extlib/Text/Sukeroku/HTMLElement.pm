package Text::Sukeroku::HTMLElement;

use strict;
no strict 'refs';
use Jcode;
use Carp qw(croak);
#use base qw(Text::Sukeroku::BaseElement);
use vars qw(@ISA);
require Text::Sukeroku::BaseElement;
push @ISA, 'Text::Sukeroku::BaseElement';

use HTML::Template;
use Text::Sukeroku::Amazon;

sub heading {
  my $self    = shift;
  my ($lv, $inline, %param) = @_;
  my $elementName  = '';
  my $anchorText   = '';
  my $symbolString = '';
  
  if($lv == 1){
    $self->{counter}->{level1}++;
    $self->{counter}->{level2} = 0;
    $self->{counter}->{level3} = 0;
    $elementName = 'h3';
    $symbolString = $self->config->heading->{symbol1};
  }
  elsif($lv == 2){
    $self->{counter}->{level2}++;
    $self->{counter}->{level3} = 0;
    $elementName = 'h4';
    $symbolString = $self->config->heading->{symbol2};
  }
  elsif($lv == 3){
    $self->{counter}->{level3}++;
    $elementName = 'h5';
    $symbolString = $self->config->heading->{symbol3};
  }

  # 見出し文字列のアンカー
  if(defined($param{'anchor'}) && $param{'anchor'} ne ''){
    $anchorText = $param{'anchor'};
    delete $param{'anchor'};
  }
  else{
    if($self->config->heading->{anchorType}){
      $anchorText = $inline;
    }
    else{
      $anchorText = qq($self->{counter}->{level1}_$self->{counter}->{level2}_$self->{counter}->{level3});
    }
  }
  $anchorText =~ s/<\w+[^>]*>//gx;
  $anchorText =~ s/(\W)/unpack('H2', $1)/eg;
  $anchorText = "id_$anchorText";
  my %anchorParam = (
    'href' => "#${anchorText}",
    'id'   => "${anchorText}",
    'name' => "${anchorText}",
    );
  
  return $self->inlineElement(
    $elementName,
    $self->inlineElement('a', $symbolString, %anchorParam) . ${inline},
    %param);
}

## 
## キーワード検索系ページへのリンク(Google, Wikipedia, はてなキーワード)
## 
sub specialKeyword{
  my $self  = shift;
  my ($scheme, $keyword, %attr) = @_;
  return ($scheme eq 'google')   ? $self->google($keyword, %attr) :
         ($scheme eq 'wikipedia')? $self->wikipedia($keyword, %attr) :
         ($scheme eq 'keyword')  ? $self->hatenaKeyword($keyword, %attr)
                                 : $keyword;
}

## 
## キーワード検索系ページへのリンク(Google)
## 
sub google{
  my $self  = shift;
  my ($keyword, %attr) = @_;
  my $url   = 'http://www.google.com/search?lr=lang_ja&ie=utf-8&oe=utf-8&q=';
  my $encoded = Jcode->new($keyword)->utf8;
  $encoded =~ s/(\W)/'%' . unpack('H2', $1)/eg;
  $encoded =~ tr/ /+/;
  $url = "$url$encoded";
  return $self->a($url, $keyword, %attr);
}
## 
## キーワード検索系ページへのリンク(Wikipedia)
## 
sub wikipedia{
  my $self  = shift;
  my ($keyword, %attr) = @_;
  my $url   = 'http://ja.wikipedia.org/wiki/';
  my $encoded = Jcode->new($keyword)->utf8;
  $encoded =~ s/(\W)/'%' . unpack('H2', $1)/eg;
  $encoded =~ tr/ /+/;
  $url = "$url$encoded";
  return $self->a($url, $keyword, %attr);
}
## 
## キーワード検索系ページへのリンク(はてなキーワード)
## 
sub hatenaKeyword{
  my $self  = shift;
  my ($keyword, %attr) = @_;
  my $url   = 'http://d.hatena.ne.jp/keyword/';
  my $encoded = Jcode->new($keyword)->euc;
  $encoded =~ s/(\W)/'%' . unpack('H2', $1)/eg;
  $encoded =~ tr/ /+/;
  $url = "$url$encoded";
  return $self->a($url, $keyword, %attr);
}

## 
## Amazon
## 
sub asinStaticText{
  my $self  = shift;
  my ($asin, $inline, %attr) = @_;
  my $aid = $self->config->amazon->{'aid'};
  my $url   = "http://www.amazon.co.jp/exec/obidos/redirect?path=ASIN/$asin" .
              '&amp;creative=1211&amp;camp=247&amp;link_code=as2' .
              ($aid ? "&amp;tag=$aid" : '' );
  return $self->a($url, $inline, %attr);
}
sub asinStaticImage{
  my $self  = shift;
  my ($asin, $title, %attr) = @_;
  my $url      = "http://images-jp.amazon.com/images/P/";
  my $size     = "MZZZZZZZ";
  my %img_attr = ('border' => '0', 'title' => $title, 'alt' => $title);
  # サイズ指定
  if(defined($attr{'size'})){
    $size = ($attr{'size'} eq 'small') ? 'THUMBZZZ':
            ($attr{'size'} eq 'large') ? 'LZZZZZZZ':
                                         'MZZZZZZZ';
    delete $attr{'size'};
  }
  # 代替画像指定
  if(defined($attr{'altimg'}) || defined($self->config->amazon->{altimg})){
    my $altimg = (defined($attr{'altimg'})) ? $attr{'altimg'} : $self->config->amazon->{altimg};
    delete $attr{'altimg'};
    $img_attr{'onload'} = "if(this.width=='1') this.src=('$altimg')";
  }
  my $img = $self->img("$url$asin.09.$size.jpg", $title, %img_attr);
  return $self->asinStaticText($asin, $img, %attr);
}
sub asinAsync{
  my $self  = shift;
  my ($asin, %attr) = @_;
  my $tmplText = $self->config->amazon_async_tmpl();
  my $tmpl = HTML::Template->new(scalarref => \$tmplText);
  $tmpl->param(Asin => $asin);
  return $tmpl->output;
}
sub asinDetail{
  my $self  = shift;
  my ($asin, %attr) = @_;

  my $token = $self->config->amazon->{'token'};
  my $aid   = $self->config->amazon->{'aid'};
  my $amaxa = Text::Sukeroku::Amazon->new((SubscriptionId =>$token, AssociateTag =>$aid));
  my @details;
  
  my $res = $amaxa->itemLookup($asin);
  my @detailData = ();

  my $d = $res->{items}[0]->{properties};
  my %thisItem;
  $thisItem{ProductName}    = $d->{Title};
  $thisItem{Asin}           = $d->{ASIN};
  $thisItem{DetailPageURL}  = $d->{DetailPageURL};
  $thisItem{ImageUrlMedium} = $d->{MediumImage}->{URL};
  $thisItem{ImageUrlSmall}  = $d->{SmallImage}->{URL};

  # ジャンル
  if($d->{ProductGroup}){
    $thisItem{ProductGroup} = $d->{ProductGroup};
  }
  # 作者
  if(($d->{Author})){
    $thisItem{Author} = join(', ', map($self->escape($_), $self->_toArray($d->{Author})));
  }
  # アーティスト
  if(($d->{Artist})){
    $thisItem{Artist} = join(', ', map($self->escape($_), $self->_toArray($d->{Artist})));
  }
  # 出演者
  if(($d->{Actor})){
    $thisItem{Actor} = join(', ', map($self->escape($_), $self->_toArray($d->{Actor})));
  }
  # 監督
  if(($d->{Director})){
    $thisItem{Director} = join(', ', map($self->escape($_), $self->_toArray($d->{Director})));
  }
  # 出版社・メーカー
  if($d->{Label}){
    $thisItem{Label} = $d->{Label};
  }
  # 出版社
  if($d->{Publisher}){
    $thisItem{Publisher} = $d->{Publisher};
  }
  # 出版社・メーカー
  if($d->{Manufacturer}){
    $thisItem{Manufacturer} = $d->{Manufacturer};
  }
  # 発売日の表示
  if($d->{ReleaseDate}){
    $thisItem{ReleaseDate} = $d->{ReleaseDate};
  }
  # 入手可能状態の表示
  if($d->{Availability}){
    $thisItem{Availability} = $d->{Availability};
  }
  # メディアの表示
  if($d->{Media}){
    $thisItem{Media} = $d->{Media};
  }
  # トラック情報の表示
  #if($d->{Tracks}){
  #}
  # プラットフォームの表示
  if($d->{Platform}){
    $thisItem{Platform} = join(', ', map($self->escape($_), $self->_toArray($d->{Platform})));
  }
  # 価格の表示
  if($d->{Price}){
    $thisItem{Price} = $d->{Price}->{FormattedPrice};
  }
  # 価格の表示
  if($d->{ListPrice}){
    $thisItem{ListPrice} = $d->{ListPrice}->{FormattedPrice};
  }
  # 売上の表示
  if($d->{SalesRank}){
    $thisItem{SalesRank} = $d->{SalesRank};
  }
  # ISBNコードの表示
  if($d->{ISBN}){
    $thisItem{ISBN} = $d->{ISBN};
  }
  # 商品紹介
  if($d->{EditorialReview}){
  #  #レビュー
  #  my @editorialReviews;
  #  if (ref($d->{EditorialReview}) eq 'ARRAY') {
  #    push(@editorialReviews,@{$d->{EditorialReview}});
  #  }
  #  elsif($d->{EditorialReview}){
  #    push(@editorialReviews, $d->{EditorialReview});
  #  }
  #  if(@editorialReviews > 0){
  #    for(my $i = 0; $i < @editorialReviews; $i++){
  #      my %thisRow;
  #      $thisRow{Name} = "紹介";
  #      $thisRow{Data} = jcode($editorialReviews[$i]->{Content}, 'utf8')->euc;
  #      push(@detailData,  \%thisRow);
  #    }
  #  }
  }
  # 評価の表示
  if($d->{CustomerReviews}){
    $thisItem{CustomerReviews} = $d->{CustomerReviews}->{AverageRating};
  }

  # Perl 5.8.0特有？のUTFフラグを強制的にオフにする
  if($self->config->amazon->{forceUtf8FlagDecode}){
    while(my($key,$value) = each(%thisItem)){
      unless(eval('use Encode;')){
        eval('if(Encode::is_utf8($value)){utf8::encode($value);}');
      }
      $thisItem{$key}= jcode($value)->utf8;
    }
  }
  
  return $self->_renderAsinDetail(%thisItem);
}

sub _renderAsinDetail{
  my $self  = shift;
  my (%paramItem) = @_;
  my $tmplText = $self->config->amazon_detail_tmpl();
  $tmplText = jcode($tmplText,'euc')->utf8;

  my $tmpl = HTML::Template->new(scalarref => \$tmplText);
  $tmpl->param(FALSE => 0);
  $tmpl->param(SubscriptionId => $self->config->amazon->{token});
  $tmpl->param(AssociateTag => $self->config->amazon->{aid});
  $tmpl->param(ProductName =>  $paramItem{ProductName});
  $tmpl->param(Asin => $paramItem{Asin});
  $tmpl->param(DetailPageURL => $paramItem{DetailPageURL});
  $tmpl->param(ImageUrlAlt   => $self->config->amazon->{altImage});
  $tmpl->param(ImageUrlSmall => $paramItem{ImageUrlSmall});
  $tmpl->param(ImageUrlMedium => $paramItem{ImageUrlMedium});
  $tmpl->param(ProductGroup => $paramItem{ProductGroup});
  $tmpl->param(Author => $paramItem{Author});
  $tmpl->param(Artist => $paramItem{Artist});
  $tmpl->param(Director => $paramItem{Director});
  $tmpl->param(Label => $paramItem{Label});
  $tmpl->param(Publisher => $paramItem{Publisher});
  $tmpl->param(Manufacturer => $paramItem{Manufacturer});
  $tmpl->param(ReleaseDate => $paramItem{ReleaseDate});
  $tmpl->param(Availability => $paramItem{Availability});
  $tmpl->param(Media => $paramItem{Media});
  $tmpl->param(Platform => $paramItem{Platform});
  $tmpl->param(Price => $paramItem{Price});
  $tmpl->param(ListPrice => $paramItem{ListPrice});
  $tmpl->param(SalesRank => $paramItem{SalesRank});
  $tmpl->param(ISBN => $paramItem{ISBN});
  $tmpl->param(CustomerReviews => $paramItem{CustomerReviews});

  my $answer = $tmpl->output;
  return $answer;
}
####------------------------------------------------------------------------
#### ネストしたXMLエレメントを配列にまとめる
####------------------------------------------------------------------------
sub _toArray(){
  # パラメータの取得
  my ($self, $items) = @_;
  my @answer;
  if (ref($items) eq 'ARRAY') {
    push(@answer,@{$items});
  }
  elsif($items){
    push(@answer,$items);
  }
  return @answer;
}
1;
