package Text::Sukeroku::HatenaDiary;
##############################################################################
## �� �ϤƤʥ������꡼���ƥ����ȥե����ޥå��ѥ��֥롼����                  ##
##       http://hsj.jp/works/archives/000324.html                           ##
##############################################################################
use strict;
no strict 'refs';
use Carp qw(croak);
#use base qw(Text::Sukeroku::BaseFormat);
use vars qw(@ISA);
require Text::Sukeroku::BaseFormat;
push @ISA, 'Text::Sukeroku::BaseFormat';

## ����ɽ�������
my $REGEXP_LINK   = '(?:(?:(?:http|https|ftp|mailto|google|anchor|keyword|wikipedia):)|(?:(?:ISBN|isbn|ASIN|asin):\w+(?::(?:image(?::\w+)|detail)?)?)|[^:])+';
my $REGEXP_FOOTNOTE = qr/\(\(.*?(?:(?:{$Text::Sukeroku::HatenaDiary::REGEXP_FOOTNOTE}).*)*?\)\)/;

sub init{
  my $self = shift;
  $self->SUPER::init();
}

sub formatText {
  my $self    = shift;
  my (@lines) = split(/\n/, $self->{source});
  
  # ������Ƭ��>|�ǳ��Ϥ�������������|<�ǽ�λ����ޤ� �����Ѥߥƥ����Ȥΰ����Ȥ���
  my $modePreLevel = 0;
  # ������Ƭ��>�ǳ��Ϥ�������������<�ǽ�λ����ޤ�<p></p>�ΰϤ߽�����Ԥ�
  my $modeParagraph = 1;
  # ������Ƭ��><!--�ǳ��Ϥ�������������--><�ǽ�λ����ޤ������Ѥߥƥ����Ȥΰ����Ȥ���
  my $modeDraft    = 0;
  
  # tag�Υ����å�������
  my (@saved, @result, @footnotes);
  # ������κǽ��Ԥξ��֤�����
  my $lastLine       = '';
  
  # ��Ԥ��ĥե����ޥåȽ����򤹤�
  foreach (@lines) {
    # ������\n�����
    chomp;
    #
    # ���񤭥ƥ�����
    #
    if (/^><!--$/) {
      if($modeDraft != 1){
        $modeDraft = 1;
      }
    }
    elsif (/^--><$/) {
      if($modeDraft == 1){
        $modeDraft = 0;
      }
    }
    elsif($modeDraft == 1){
      #�ǽ������ԡ����֤���¸
      $lastLine       = $_;
      next;
    }
    #
    # �����Ѥߥƥ�����(����)
    #
    elsif (/^>(\|{1,2})$/) {
      if($modePreLevel == 0){
        push(@result, splice(@saved));
        push(@result, $self->html->openElement('pre', ()));
        $modePreLevel = length($1);
      }
    }
    #
    # �����Ѥߥƥ�����(��λ)
    #
    elsif (/^(|\S.*)(\|{1,2})<$/) {
      if($1 ne ''){
        if($modePreLevel == 2){
          push(@result, $self->html->escape($1));
        }
        else{
          push(@result, $1);
        }
      }

      if($modePreLevel == length($2)){
        push(@result, splice(@saved));
        push(@result, $self->html->closeElement('pre'));
        $modePreLevel = 0;
      }
    }
    # >|...>|�ξ��˥ե饰��ON�ʤ��HTML���������פ�»ܤ��롣
    # �ʹߤν����ϥ����åפ���ʺǽ��Ԥμ����ϹԤ���
    elsif($modePreLevel == 2){
      push(@result, $self->html->escape($_));
      $lastLine       = $_;
      next;
    }
    #
    # ���󥫡��դ����Ф� 
    #
    elsif (/^(\*{1,3})([^\*]+)\*(.*)$/) {
      push(@result, splice(@saved), $self->html->heading(length($1), $self->_parseInlineText($3, \@footnotes), ('anchor' => $2)));
    }
    #
    # ���Ф� 
    #
    elsif (/^(\*{1,3})(.*)/) {
      push(@result, splice(@saved), $self->html->heading(length($1), $self->_parseInlineText($2, \@footnotes), ()));
    }
    #
    # �ꥹ��ɽ����
    #
    elsif (/^(-+)(.*)$/) {
      $self->backPush('ul', length($1), \@saved, \@result, ());
      push(@result, $self->html->inlineElement('li', $self->_parseInlineText($2, \@footnotes), ()));
    }
    elsif (/^(\++)(.*)$/) {
      $self->backPush('ol', length($1), \@saved, \@result, ());
      push(@result, $self->html->inlineElement('li', $self->_parseInlineText($2, \@footnotes), ()));
    }
    #
    # �Ѹ����
    #
    elsif(/^:($REGEXP_LINK)?:(.*)/){
      $self->backPush('dl', 1, \@saved, \@result, ());
      if(defined($1) && $1 ne ''){
        push(@result, $self->html->inlineElement('dt', $self->_parseInlineText($1, \@footnotes), ()));
      }
      push(@result, $self->html->inlineElement('dd', $self->_parseInlineText($2, \@footnotes), ()));
    }
    #
    # ����
    #

    # ����ʸ
    elsif (/^>>=((.+?)(?::|\>))?((http|https):([^\x00-\x20()<>\x7F-\xFF])*)$/) {
      push(@result, splice(@saved));
      push(@result, $self->html->openElement('blockquote', (
        'title' => $2,
        'cite'  => $3,
        )));
    }
    elsif (/^>>$/) {
      push(@result, splice(@saved));
      push(@result, $self->html->openElement('blockquote', ()));
    }
    elsif (/^<<$/) {
      push(@result, splice(@saved));
      push(@result, $self->html->closeElement('blockquote'));
    }
    elsif (/^$/){
      push(@result, splice(@saved));
      if($lastLine =~ /^$/){
        push(@result, $self->html->br());
      }
    }
    # ɽ�Ȥ�
    # This part is taken from Mr. Ohzaki's Perl Memo and Makio Tsukamoto's WalWiki.
    elsif (/^\|(.*?)[\x0D\x0A]*\|$/) {
      $self->backPush('table', 1, \@saved, \@result, ());
      my $tmp     = "$1";
      my @value   = split(/\|/, $tmp);
      my @th      = map {(s/^\*//) ? 1 : 0} @value;
      my @style   = map {''} @value;
      push(@result, $self->html->openElement('tr', ()));
      for (my $i = 0; $i < @value; $i++) {
        my $cellElement = ($th[$i]) ? 'th' : 'td';
        push(@result,
             $self->html->inlineElement($cellElement, $self->_parseInlineText($value[$i], 0, \@footnotes), ()));
      }
      push(@result, $self->html->closeElement('tr'));
    }
    #
    else {
      # �����å����Ǥ��Ф�
      push(@result, splice(@saved));
      # ����ʸ���ǤϤ��ޤꡢ�����ƥ����Ƚ��ϤǤʤ��ʤ�<p></p>�ղ�
      if (/^\s+/) {
        ($modeParagraph == 1 &&
         $modePreLevel != 1) ? push(@result, $self->html->inlineElement('p', $_, ()))
                             : push(@result, ($_));
      }
      else{
        my $inlineText = $_;

        # ������Ƭ��������><��Ƚ��
        if (/^>(<.*>)<$/) {
          $modeParagraph = 0;
          $inlineText = $1;
        }
        elsif (/^>(<.*)/) {
          $modeParagraph = 0;
          $inlineText = $1;
        }
        elsif (/(.*>)<$/) {
          $inlineText = $1;
        }
        
        if($self->config->html->{convertLineBreak}){
          $inlineText = $inlineText . $self->html->br();
        }

        # ����饤�����Ǥ�Ÿ��
        $inlineText = $self->_parseInlineText($inlineText, \@footnotes);
        
        # <p>�ղü»�Ƚ��塢����饤�������
        if($modeParagraph == 1 && $modePreLevel != 1){
          $inlineText = $self->html->inlineElement('p', $inlineText, ());
          $inlineText =~ s|(<p>.*)(<div.*?>.*</div>)(.*</p>)|$1</p>$2<p>$3|gisx;
          $inlineText =~ s|(<p>.*)(<script.*?>.*</script>)(.*</p>)|$1</p>$2<p>$3|gisx;
        }
        push(@result, $inlineText);

        # ><�ǽ���äƤ������<p>�ղåե饰��Ω�Ƥ롣
        if (/><$/) {
          $modeParagraph = 1;
        }
      }
    }
    #�ǽ������ԡ����֤���¸
    $lastLine       = $_;
  }

  # �����å��򤹤٤Ʋ����Ф�������򶴤ߡ����٤Ʋ���ʸ���򶴤߹��߽��ϡ�
  push(@result, splice(@saved));
  if(@footnotes > 0){
    push(@result, $self->formatFootnoteList(\@footnotes));
  }
  return join("\n", @result);
}

sub _parseInlineText{
  my $self = shift;
  my ($inlineText, $footnoteRef) = @_;
  
  # �� ��ư���
  if(/(http|https|ftp|mailto|ISBN|isbn|ASIN|asin|google|anchor|keyword|wikipedia):.*/){
    # ���ޤ��ޤʥѥ�����ˤĤ���ʬ��
    $inlineText =~ s!(
      # []URL[]
      (\[\](http|https|ftp|mailto|isbn|asin|ISBN|ASIN|anchor):([^\x00-\x20()<>\x7F-\xFF])*\[\])
      |
      # [URL]
      (\[(http|https|ftp|mailto|isbn|asin|ISBN|ASIN|anchor):([^\x00-\x20()<>\x7F-\xFF])*(:title=.*)?\])
      |
      # [google:WORDs]
      (\[(google):[^\]]+\])
      |
      # [wikipedia:WORDs]
      (\[(wikipedia):[^\]]+\])
      |
      # [keyword:WORDs]
      (\[(keyword):[^\]]+\])
      |
      # [anchor:WORDs]
      (\[(anchor):[^\]]+\])
      |
      # src="URL", href="url"
      ((src|href|cite)=[\'\"](http|https|ftp|mailto|isbn|asin|ISBN|ASIN|anchor):([^\x00-\x20()<>\x7F-\xFF])*[\'\"])
      |
      # URL
      ((http|https|ftp|mailto|isbn|asin|ISBN|ASIN|anchor):([^\x00-\x20()<>\x7F-\xFF])*)
      )!$self->_parseInlineAnchor($1)!igex;
  }
  # �� ������ɥ��
  if(/\[\[([^\]]+)\]\]/){
    $inlineText =~ s!(
      (\[\[[^\]]+\]\])
      )!$self->_parseInlineAnchor($1)!gex;
  }
  # �� ����
    if(/$REGEXP_FOOTNOTE/){
      my $funcFootnoteSwitch = sub{
        my ($localString) = @_;
        if($localString =~ /^\(\(\(/ ){
          $localString = $localString;
        }
        elsif($localString =~ /^\)(\(\(.+\)\))\($/ ){
          $localString = $1;
        }
        elsif($localString =~ /^\(\((.+)\)\)$/ ){
          $localString = $self->formatFootnoteAnchor($self->addFootnoteList(\@$footnoteRef, '', $1));
        }
        return $localString;
      };
      # ���ޤ��ޤʥѥ�����ˤĤ���
      $inlineText =~ s!(
        (\($REGEXP_FOOTNOTE\))
        |
        (\)$REGEXP_FOOTNOTE\()
        |
        ($REGEXP_FOOTNOTE)
        )!&$funcFootnoteSwitch($1)!gex;
    }
  return $inlineText;
}

sub _parseInlineAnchor {
  my $self = shift;
  my ($inlineText) = @_;

  #[]URL[]�Ĥ��Τޤ޽���
  if($inlineText =~ /^\[\](.+)\[\]$/ ){
    $inlineText = $1;
  }
  #[[Words]]�ĥ�����ɰ���
  elsif($inlineText =~ /^\[\[(.+)\]\]$/ ){
    $inlineText = $self->anchorElement($self->config->html->{default_keyword} . ':'. $1, $1, ());
  }
  #[URL]��URL���ڤ�Ф�
  elsif($inlineText =~ /^\[(.+):title=(.+)\]$/ ){
    $inlineText = $self->anchorElement($1, $2, ());
  }
  #[URL]��URL���ڤ�Ф�
  elsif($inlineText =~ /^\[(.+)\]$/ ){
    $inlineText = $self->anchorElement($1, $1, ());
  }
  #[URL]��amazon��ͭ����
  elsif($inlineText =~ /^(src|href|cite)=[\'\"](.+)[\'\"]$/i ){
    my $localAttr = $1;
    my $localUrl  = $2;
    if($localUrl =~ /^(ISBN|isbn|ASIN|asin)/){
      my $localTempAnswer = $self->anchorElement($localUrl, $localUrl, ());
      $localTempAnswer =~ s|<a .*href=\"(.+)\".+|$1|x;
      $inlineText = qq(${localAttr}="${localTempAnswer}");
    }
    else{
      ;#$inlineText ���Τޤ޽���
    }
  }
  #URL���ڤ�Ф�
  else{
    $inlineText = $self->anchorElement($inlineText, $inlineText, ());
  }
  return $inlineText;
};

1;
