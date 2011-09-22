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
  # �Ƽ�����
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
  
  # ���٤Ʋ���ʸ���򶴤߹��߽��ϡ�
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
  ## http, https, ftp�ץ�ȥ����URI
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
  ## �����륢�󥫡�������
  ##
  elsif ($addr =~ /^(anchor|\#):(.+)/) {
    # ���
    my $anchorString = $2;
    # ���إƥ����Ȥ�����
    if(defined($title)){
      if($title eq ''){
        $title = $anchorString;
      }
    }
    else{
      $title = $anchorString;
    }
    # �������
    $anchorString =~ s/(\W)/'%' . unpack('H2', $1)/eg;
    $answer = $self->html->a("#${anchorString}", $title, %attr);
  }
  ##
  ## ASIN,ISBN������(detail)
  ##
  elsif ($addr =~ /^(ISBN|ASIN|isbn|asin):([0-9A-Z\-]+):detail/) {
    my $asin = $2;
    $asin   =~ s/-//g;
    $answer =  $self->html->asinDetail($2);
  }
  ##
  ## ASIN,ISBN������(async)
  ##
  elsif ($addr =~ /^(ISBN|ASIN|isbn|asin):([0-9A-Z\-]+):async/) {
    my $asin = $2;
    $asin   =~ s/-//g;
    $answer =  $self->html->asinAsync($2);
  }
  ##
  ## ASIN,ISBN������
  ##
  elsif ($addr =~ /^(ISBN|ASIN|isbn|asin):([0-9A-Z\-]+)(:image(:(small|large))?)?/) {
    # ���
    my ($asin, $image)  = ($2, $3);
    $asin =~ s/-//g;
    # Amazon���ɽ�����ץ����(:image)
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
  ## mailto(�᡼�륢�ɥ쥹)
  ##
  elsif ($addr =~ /^(mailto\:)?(.+\@.+)/) {
    # mailto:���ʤ�������Ƥ�
    my $mailAddr = ($1 eq '') ? 'mailto:' . $addr : $addr;
    my $altText  = ($title eq '') ? $2 : $title;
    $answer      = $self->html->a($mailAddr, $altText, %attr);
  }
  ##
  ## Google/�ϤƤʥ������/Wikipedia
  ##
  elsif ($addr =~ /^(google|keyword|wikipedia):(.+)/) {
    # ���
    my $scheme = lc($1);
    my $word   = $2;
    $answer = $self->html->specialKeyword($scheme, $word, %attr);
  }
  ##
  ## ����ʳ��ξ��
  ##
  else{
      $answer = $self->html->a($addr, $title, %attr);
  }
  return $answer;
}

##
## ����ꥹ�Ȥ��ɲä�������ʸ�ؤΥ�󥯤Τ���κ����Υϥå����ե���󥹤��ֵѤ��롣
##
sub addFootnoteList{
  my $self     = shift;
  my ($refFootnotes, $fnLinked, $fnBody) = @_;
  my $fnNumber = ++$self->{footnote}->{counter};
  my $permalink = '';
  my $fnKey = "footnote_${fnNumber}_";

  # MT��ͭ���ʤȤ��ϥ���ȥ꡼ID�ȥƥ����ȥѡ��Ȥ���Ϳ���롣
  if(defined($self->{mt}) && $self->{mt}{'imported'}){
    $fnKey .= $self->{mt}{'entry_id'} . '_'. $self->{mt}{'text_part'} . '_';
    $permalink = $self->{mt}{'permalink'};
  }
  # �ϥå����ե���󥹤�����
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
## ����ʸ�ؤΥ�󥯤���������
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
## ����ʸ���Τ���������
##
sub formatFootnoteBody{
  my $self    = shift;
  my %fnItem  = @_;
  my $fnKey   = $fnItem{'key'};
  my $href    = "$fnItem{'permalink'}#$fnItem{'key'}_root";
  # TODO...����ܥ������
  my $inline  =  $self->config->footnote->{symbol1} . $fnItem{'counter'};
  my %attr    = ();

  # ������ʸ
  $attr{'id'}   = $fnKey;
  unless($self->config->html->{flavor} eq 'xhtml'){
    $attr{'name'} = $fnKey;
  }
  return $self->html->a($href, $inline, %attr) . ": " . $fnItem{'body'};
}

##
## ����ʸ�ꥹ�Ȥ���������
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
