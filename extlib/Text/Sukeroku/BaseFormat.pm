package Text::Sukeroku::BaseFormat;

use strict;
no strict 'refs';
use Carp qw(croak);

use LWP::UserAgent;
use XML::Simple;
use Jcode;
use Text::Sukeroku::HTMLElement;
use Text::Sukeroku::Kiseru;

sub new{
  my $class  = shift;
  my $source = shift  || croak ('source is not exist!!');
  my $param  = shift if (@_);
  
  ## TODO
  my $config = Text::Sukeroku::Kiseru->new();
  my $html   = Text::Sukeroku::HTMLElement->new({
    config => $config,
    });
  my %mt = (
        "imported"  => 0,
        "permalink" => '',
        "entry_id"  => '',
        "text_part" => '',
        "charset"   => '',
    );

  
  $source =~ s|\r\n|\n|g;
  $param->{source} = $source;
  $param->{html}   = $html;
  $param->{config} = $config;
  $param->{mt} = %mt;
  
  init($param);
  
  bless $param,$class;
}

sub init{
  my $self  = shift;
  my @emptyList;
  # 各種初期化
  $self->{footnote}->{counter} = 0;
  $self->{footnote}->{list} = ();
}

sub html {
  my $self    = shift;

  if(@_){
    $self->{html} = @_;
  }
  else{
    return $self->{html};
  }
}

sub config {
  my $self    = shift;

  if(@_){
    $self->{config} = @_;
  }
  else{
    return $self->{config};
  }
}

sub formatText {
  my $self    = shift;
  my (@lines) = split(/\n/, $self->{source});
  
  # すべて改行文字を挟み込み出力。
  return join("\n", join("<br/>\n",@lines));
}

sub cutOffEmptyParagraph{
  my $self    = shift;
  my ($savedref, $resultref) = @_;
  
  if(scalar(@{$resultref}) > 0 && scalar(@{$savedref}) > 0){
    if($resultref->[-1] eq '<p>' && $savedref->[0] eq '</p>'){
      pop(@$resultref);
      shift(@$savedref);
    }
  }
}

sub backPush {
  my $self    = shift;
  my ($tag, $level, $savedref, $resultref, %attr) = @_;
  $self->cutOffEmptyParagraph($savedref, $resultref);
  while (@$savedref > $level) {
    push(@$resultref, shift(@$savedref));
  }
  if(scalar(@{$savedref}) > 0){
    my $closeTag = $self->html->closeElement($tag);
    if(!($savedref->[0] =~ /$closeTag/)) {
      push(@{$resultref}, "<!-- xxx -->");
      push(@{$resultref}, splice(@{$savedref}));
      push(@{$resultref}, "<!-- xxx -->");
    }
  }
  while (@$savedref < $level) {
    unshift(@$savedref, $self->html->closeElement($tag));
    if($self->config->html->{flavor} eq 'xhtml'){
      if(scalar(@{$savedref}) > 1){
        my $regexp_last = '</(ul|ol)>(</li>)?';
        if($savedref->[1] =~ /$regexp_last/){
          $resultref->[-1] =~ s|</li>$||;
          shift(@$savedref);
          unshift(@$savedref, $self->html->closeElement($tag) . $self->html->closeElement('li'));
        }
      }
    }
    push(@$resultref, $self->html->openElement($tag, %attr));
  }
}

sub anchorElement{
  my $self = shift;
  my ($addr, $title, %attr) = @_;
  my $answer = '';

  ##
  ## http, https, ftpプロトコルのURI
  ##
  if ($addr =~ /^(http|https|ftp):/) {
    if ($self->config->html->{linkAutoImage} and $addr =~ /\.(gif|png|jpeg|jpg)$/) {
      my $img = $self->html->img($addr, $title, ('border' => '0'));
      $answer = $self->html->a($addr, $img, %attr);
    }
    else {
      $answer = $self->html->a($addr, $title, %attr);
    }
  }
  ##
  ## ローカルアンカージャンプ
  ##
  elsif ($addr =~ /^(anchor|\#):(.+)/) {
    # 宣言
    my $anchorString = $2;
    # 代替テキストの設定
    if(defined($title)){
      if($title eq ''){
        $title = $anchorString;
      }
    }
    else{
      $title = $anchorString;
    }
    # リンク生成
    $anchorString =~ s/(\W)/'%' . unpack('H2', $1)/eg;
    $answer = $self->html->a("#${anchorString}", $title, %attr);
  }
  ##
  ## ASIN,ISBNコード(detail)
  ##
  elsif ($addr =~ /^(ISBN|ASIN|isbn|asin):([0-9A-Z\-]+):detail/) {
    my $asin = $2;
    $asin   =~ s/-//g;
    $answer =  $self->html->asinDetail($2);
  }
  ##
  ## ASIN,ISBNコード(async)
  ##
  elsif ($addr =~ /^(ISBN|ASIN|isbn|asin):([0-9A-Z\-]+):async/) {
    my $asin = $2;
    $asin   =~ s/-//g;
    $answer =  $self->html->asinAsync($2);
  }
  ##
  ## ASIN,ISBNコード
  ##
  elsif ($addr =~ /^(ISBN|ASIN|isbn|asin):([0-9A-Z\-]+)(:image(:(small|large))?)?/) {
    # 宣言
    my ($asin, $image)  = ($2, $3);
    $asin =~ s/-//g;
    # Amazon書影表示オプション(:image)
    if(defined($image) && $image ne ''){
      if($image =~ /:small$/){
        $attr{'size'} = 'small';
      }
      if($image =~ /:large$/){
        $attr{'size'} = 'large';
      }
      $answer = $self->html->asinStaticImage($asin, $title, %attr);
    }
    else{
      $answer = $self->html->asinStaticText($asin, $title, %attr);
    }
  }
  ##
  ## mailto(メールアドレス)
  ##
  elsif ($addr =~ /^(mailto\:)?(.+\@.+)/) {
    # mailto:がない場合は補てん
    my $mailAddr = ($1 eq '') ? 'mailto:' . $addr : $addr;
    my $altText  = ($title eq '') ? $2 : $title;
    $answer      = $self->html->a($mailAddr, $altText, %attr);
  }
  ##
  ## Google/はてなキーワード/Wikipedia
  ##
  elsif ($addr =~ /^(google|keyword|wikipedia):(.+)/) {
    # 宣言
    my $scheme = lc($1);
    my $word   = $2;
    $answer = $self->html->specialKeyword($scheme, $word, %attr);
  }
  ##
  ## それ以外の場合
  ##
  else{
      $answer = $self->html->a($addr, $title, %attr);
  }
  return $answer;
}

##
## 脚注リストに追加し、脚注文へのリンクのための材料のハッシュリファレンスを返却する。
##
sub addFootnoteList{
  my $self     = shift;
  my ($refFootnotes, $fnLinked, $fnBody) = @_;
  my $fnNumber = ++$self->{footnote}->{counter};
  my $permalink = '';
  my $fnKey = "footnote_${fnNumber}_";

  # MTが有効なときはエントリーIDとテキストパートも付与する。
  if(defined($self->{mt}) && $self->{mt}{'imported'}){
    $fnKey .= $self->{mt}{'entry_id'} . '_'. $self->{mt}{'text_part'} . '_';
    $permalink = $self->{mt}{'permalink'};
  }
  # ハッシュリファレンスの生成
  my %fnItem =(
    'counter'   => $fnNumber,
    'permalink' => $permalink,
    'text'      => $fnLinked,
    'key'       => $fnKey,
    'body'      => $fnBody,
    );
  push @$refFootnotes, \%fnItem;
  return %fnItem;
}

##
## 脚注文へのリンクを生成する
##
sub formatFootnoteAnchor{
  my $self    = shift;
  my %fnItem  = @_;
  my $fnKey   = "$fnItem{'key'}_root";
  my $href    = "$fnItem{'permalink'}#$fnItem{'key'}";
  my $inline  = $fnItem{'text'} . $self->config->footnote->{symbol1} . $fnItem{'counter'};
  my %attr    = ();

  my $tagSpan    = $self->config->footnote->{html}->{tagRoot};
  my %attrSpan   = ();
  $attrSpan{'class'} = $self->config->footnote->{html}->{classRoot};
  $attrSpan{'title'} = $fnItem{'body'};
  $attrSpan{'title'} =~ s|<img .*alt=['"](.*)["'].*>|$1|igx;
  $attrSpan{'title'} =~ s|<.+?>(.*)</.+?>|$1|igx;
  
  $attr{'id'}   = $fnKey;
  unless($self->config->html->{flavor} eq 'xhtml'){
    $attr{'name'} = $fnKey;
  }

  return $self->html->inlineElement($tagSpan, $self->html->a($href, $inline, %attr), %attrSpan);
}
##
## 脚注文本体を生成する
##
sub formatFootnoteBody{
  my $self    = shift;
  my %fnItem  = @_;
  my $fnKey   = $fnItem{'key'};
  my $href    = "$fnItem{'permalink'}#$fnItem{'key'}_root";
  # TODO...シンボルの選択。
  my $inline  =  $self->config->footnote->{symbol1} . $fnItem{'counter'};
  my %attr    = ();

  # 脚注本文
  $attr{'id'}   = $fnKey;
  unless($self->config->html->{flavor} eq 'xhtml'){
    $attr{'name'} = $fnKey;
  }
  return $self->html->a($href, $inline, %attr) . ": " . $fnItem{'body'};
}

##
## 脚注文リストを生成する
##
sub formatFootnoteList{
  my $self            = shift;
  my $refFootnoteList = shift;
  my @result;
  my $ptrCfg = $self->config->footnote->{html};
  my %attr   = ();
  $attr{'class'} = $ptrCfg->{classRoot};
  
  push(@result, $self->html->openElement($ptrCfg->{tagList}, %attr));
  foreach my $footnote(@$refFootnoteList){
    if($ptrCfg->{tagList} ne ''){
      $attr{'class'} = $ptrCfg->{classList};
      push(@result, $self->html->openElement($ptrCfg->{tagItem}, %attr));
      push(@result, $self->formatFootnoteBody(%$footnote));
      push(@result, $self->html->closeElement($ptrCfg->{tagItem}));
    }
    else{
      push(@result, $self->formatFootnoteBody(%$footnote));
      push(@result, $self->html->br());
    }
  }
  push(@result, $self->html->closeElement($self->config->footnote->{html}->{tagList}));
  return join("\n", @result);
}

1;
