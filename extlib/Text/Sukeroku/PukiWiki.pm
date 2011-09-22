package Text::Sukeroku::PukiWiki;
##----------------------------------------------------------------------
## Text::Sukeroku::PukiWiki
##----------------------------------------------------------------------
## PukiWiki���ƥ����ȥե����ޥå�
##       http://hsj.jp/works/archives/000317.html
##----------------------------------------------------------------------

use strict;
no strict 'refs';
use Carp qw(croak);
#use base qw(Text::Sukeroku::BaseFormat);
use vars qw(@ISA);
require Text::Sukeroku::BaseFormat;
push @ISA, 'Text::Sukeroku::BaseFormat';

##----------------------------------------------------------------------
## ����ɽ��
##----------------------------------------------------------------------
my $REGEXP_ITALIC = qq('''([^']+?)'''); #'
my $REGEXP_BOLD   = qq(''([^']+?)'');   #'
my $REGEXP_INSERT = qq(%%%([^%]+?)%%%); #
my $REGEXP_DELETE = qq(%%([^%]+?)%%);   #
my $REGEXP_FOOTNOTE = qr/\(\(.*?(?:(?:{$Text::Sukeroku::PukiWiki::REGEXP_FOOTNOTE}).*)*?\)\)/;
my $REGEXP_PLUGIN = qr/&amp;(\w+)\([^)]*\)({([^}]*(?:(?:{$Text::Sukeroku::PukiWiki::REGEXP_PLUGIN}).*)*)})?;/;

sub init{
  my $self = shift;
  $self->SUPER::init();
}

sub formatText {
  my $self    = shift;
  my (@lines) = split(/\n/, $self->{source});

  # �С��٥�����⡼�ɡ�0=�ʤ���1=�����
  my $format_mode_verbatim = 0;
  my $verbatimEnabled = $self->config->pukiwiki->{verbatimEnabled};
  my $regexpOpenHardVerbatim  = '';
  my $regexpCloseHardVerbatim = '';
  my $regexpOpenSoftVerbatim  = '';
  my $regexpCloseSoftVerbatim = '';
  if($verbatimEnabled){
    $regexpOpenHardVerbatim  = $self->config->pukiwiki->{verbatimHardOpenRegexp};
    $regexpCloseHardVerbatim = $self->config->pukiwiki->{verbatimHardCloseRegexp};
    $regexpOpenSoftVerbatim  = $self->config->pukiwiki->{verbatimSoftOpenRegexp};
    $regexpCloseSoftVerbatim = $self->config->pukiwiki->{verbatimSoftCloseRegexp};
  }
  
  # tag�Υ����å�������
  my (@saved, @result, @footnotes);
  unshift(@saved, "</p>");
  push(@result, "<p>");
  
  #-----------------------------------------------------------------
  # ��Ԥ��ĥե����ޥåȽ����򤹤�
  #-----------------------------------------------------------------
  foreach (@lines) {
    
    # ������\n�����
    chomp;

    # �С��٥�����⡼��(Hard�⡼�ɤ�ͥ�踡�����ޤ�)
    if($verbatimEnabled){
      if($format_mode_verbatim >= 1){
        if(/$regexpCloseHardVerbatim/ && $format_mode_verbatim == 2){
          $format_mode_verbatim = 0;
        }
        elsif(/$regexpCloseSoftVerbatim/ && $format_mode_verbatim == 1){
          $format_mode_verbatim = 0;
        }
        else{
          ($format_mode_verbatim == 1) ? push(@result, $_) : push(@result, $self->html->escape($_));
        }
        next;
      }
      elsif(/$regexpOpenHardVerbatim/){
        $format_mode_verbatim = 2;
        next;
      }
      elsif(/$regexpOpenSoftVerbatim/){
        $format_mode_verbatim = 1;
        next;
      }
    }
    
    # ���Ф�
    if (/^(\*{1,3})(.*)/) {
      $self->cutOffEmptyParagraph(\@saved, \@result);
      push(@result, splice(@saved), $self->html->heading(length($1), $self->_parseInlineText($2, 0, \@footnotes), ()));
    }
    # ��ʿ��
    elsif (/^----/) {
      $self->cutOffEmptyParagraph(\@saved, \@result);
      push(@result, splice(@saved), $self->html->hr(()));
    }
    # �ꥹ��
    elsif (/^(-{1,3})(.*)/) {
      $self->backPush('ul', length($1), \@saved, \@result, ());
      push(@result, qq(<li>) , $self->_parseInlineText($2, 0, \@footnotes) , qq(</li>));
    }
    # �ֹ�ꥹ��
    elsif (/^(\+{1,3})(.*)/) {
      $self->backPush('ol', length($1), \@saved, \@result, ());
      push(@result, qq(<li>) , $self->_parseInlineText($2, 0, \@footnotes) , qq(</li>));
    }
    # ����ꥹ��
    elsif (/^(\:{1,3})([^\|]*)\|(.*)/) {
      $self->backPush('dl', length($1), \@saved, \@result, ());
      push(@result, qq(<dt>) . $self->_parseInlineText($2, 0, \@footnotes) . qq(</dt>),
           qq(<dd>) , $self->_parseInlineText($3, 0, \@footnotes) , qq(</dd>));
    }
    # ����ʸ
    elsif (/^(>{1,3})=((.+?)(?::|\>))?((http|https):([^\x00-\x20()<>\x7F-\xFF])*)/){
      $self->backPush('blockquote', length($1), \@saved, \@result, ('title'=>$3, 'cite'=>$4 ));
    }
    # ����ʸ
    elsif (/^(>{1,3})(.*)/) {
      $self->backPush('blockquote', length($1), \@saved, \@result,());
      push(@result, $self->_parseInlineText($2, 0, \@footnotes));
      if($self->config->html->{convertLineBreak}){
        push(@result, $self->html->br(()));
      }
    }
    # ����
    elsif (/^$/) {
      push(@result, splice(@saved));
      unshift(@saved, "</p>");
      push(@result, "<p>");
    }
    # �����Ѥߥƥ�����
    elsif (/^ (.*)$/) {
      $self->backPush('pre', 1, \@saved, \@result, ());
      push(@result, $self->html->escape($1));
    }
    # ����
    elsif (/^\#br/) {
      push(@result, splice(@saved), '<br />');
    }
    # �󤻥��ꥢ
    elsif (/^\#clear/) {
      $self->cutOffEmptyParagraph(\@saved, \@result);
      push(@result, splice(@saved), '<div style="margin:0px;clear:both;line-height:0%;"></div>');
    }
    # ����
    elsif (/^\#ref\((.+)\)$/) {
      my $localRefParam = $1;
      # ����޶��ڤ꤬�����
      if($localRefParam =~ /^([^,]+)(,.+)$/){
        push(@result, splice(@saved), $self->_parseRef($self->anchorElement($1, ''), $2));
      }
      else{
        push(@result, splice(@saved), $self->anchorElement($localRefParam, ''));
      }
    }
    # ������
    elsif (/^\#verb\((.+)\)$/) {
      push(@result, $self->html->unescape($1));
    }
    #//�ǤϤ��ޤ�Ԥϥ�����
    elsif (/^\/\/.*/) {
    }
    # ɽ�Ȥ�(CSV) ,YukiWiki����ޤ뤴�Ȱ��ѡ�
    # This part is taken from Mr. Ohzaki's Perl Memo and Makio Tsukamoto's WalWiki.
    elsif (/^\,(.*?)[\x0D\x0A]*$/) {
      $self->backPush('table', 1, \@saved, \@result, ());
      my $tmp = "$1,";
      my @value = map {/^"(.*)"$/ ? scalar($_ = $1, s/""/"/g, $_) : $_} ($tmp =~ /("[^"]*(?:""[^"]*)*"|[^,]*),/g); # ";
      my @align = map {(s/^ +//) ? ((s/ +$//) ? ' align="center"' : ' align="right"') : ''} @value;
      my @colspan = map {($_ eq '==') ? 0 : 1} @value;
      for (my $i = 0; $i < @value; $i++) {
        if ($colspan[$i]) {
          while ($i + $colspan[$i] < @value and $value[$i + $colspan[$i]] eq '==') {
            $colspan[$i]++;
          }
          $colspan[$i] = ($colspan[$i] > 1) ? sprintf(' colspan="%d"', $colspan[$i]) : '';
          $value[$i] = sprintf('<td%s%s>%s</td>', $align[$i], $colspan[$i], $self->_parseInlineText($value[$i], 0, \@footnotes));
        }
        else {
          $value[$i] = '';
        }
      }
      push(@result, join('', '<tr>', @value, '</tr>'));
    }
    # ɽ�Ȥ�
    # This part is taken from Mr. Ohzaki's Perl Memo and Makio Tsukamoto's WalWiki.
    elsif (/^\|(.*?)[\x0D\x0A]*\|$/) {
      $self->backPush('table', 1, \@saved, \@result, ());
      my $tmp     = "$1";
      my @value   = split(/\|/, $tmp);
      my @colspan = map {($_ eq '>') ? 0 : 1} @value;
      my @th      = map {(s/^~//) ? 1 : 0} @value;
      my @style   = map {''} @value;
      for (my $i = 0; $i < @value; $i++) {
        while($value[$i] =~ s/^((LEFT|CENTER|RIGHT)?((BG)?COLOR\(([^\)]+)\))?(SIZE\(([^\)]+)\))?:)//i){
          my $localMatch = $1;
          if($localMatch =~ /^(LEFT|CENTER|RIGHT):$/i){
            $style[$i] .= "text-align:" . lc($1) . ";";
          }
          elsif($localMatch =~ /^((?:BG)?COLOR)\(([^\)]+)\):$/i){
            $style[$i] .= (lc($1) eq 'color') ? "color:$2;"
                                              : "background-color:$2;";
          }
          elsif($localMatch =~ /^(size)\(([^\)]+)\):$/i){
            $style[$i] .= "font-size:$2px;";
          }
        }
      }
      for (my $i = 0; $i < @value; $i++) {
        if ($colspan[$i] == 1) {
          while ($i - $colspan[$i] >= 0 and $value[$i - $colspan[$i]] eq '>') {
            $value[$i - $colspan[$i]]  = '';
            $colspan[$i]++;
          }
          $colspan[$i] = ($colspan[$i] > 1) ? sprintf(' colspan="%d"', $colspan[$i])
                                            : ' nowrap="nowrap" ';
          my $thisCellTag = ($th[$i]) ? 'th'
                                      : 'td';
          $value[$i] = sprintf('<%s%s style="%s">%s</%s>', $thisCellTag, $colspan[$i], $style[$i], $self->_parseInlineText($value[$i], 0, \@footnotes), $thisCellTag);
        }
      }
      push(@result, join('', '<tr>', @value, '</tr>'));
    }
    # ���󤻡�����󤻡�����
    elsif (/^(LEFT|CENTER|RIGHT)\:(.*)/i) {
      my $localTextAlign = lc($1);
      $self->backPush('div', 1, \@saved, \@result, ( 'style'=> "text-align:${localTextAlign};" ));
      push(@result, $self->_parseInlineText($2, 0, \@footnotes));
      if($self->config->html->{convertLineBreak}){
        push(@result, $self->html->br(()));
      }
    }
    # ����ʹ�Ƭ�ü�ʸ�����������״ޤ��
    elsif (/^(\~)?(.*)$/) {
      my $thisLine   = $2;
      my $lastResult = pop(@result);

      if($lastResult =~ /<\/(li|dd|blockquote)>/){
        if($self->config->html->{convertLineBreak}){
          push(@result, $self->html->br(()));
        }
        push(@result, $self->_parseInlineText($thisLine, 0, \@footnotes), $lastResult);
      }
      else{
        push(@result, $lastResult, $self->_parseInlineText($thisLine, 0, \@footnotes));
        if($self->config->html->{convertLineBreak}){
          push(@result, $self->html->br(()));
        }
      }
    }
  }

  # �����å��򤹤٤Ʋ����Ф�������򶴤ߡ����٤Ʋ���ʸ���򶴤߹��߽��ϡ�
  # �������ǥե�������Ǥ���¸�ߤ��ʤ����϶��Ԥ��֤���
  push(@result, splice(@saved));
  if($#result > 1){
    if($self->config->pukiwiki->{bottomClearOutput}){
      push(@result, '<div style="margin:0px;clear:both;line-height:0%;"></div>');
    }

    ## ����
    if(@footnotes > 0){
      push(@result, $self->formatFootnoteList(\@footnotes));
    }
  }
  else{
    return "";
  }

  # �����å��򤹤٤Ʋ����Ф������٤Ʋ���ʸ���򶴤߹��߽��ϡ�
  push(@result, splice(@saved));
  return join("\n", @result);
}

sub _parseInlineText{
  my $self = shift;
  my $inlineText = shift;
  my ($nestLevel, $footnoteRef) = @_;
  if(!defined($inlineText)){
    $inlineText = '';
  }
  if(!defined($nestLevel) || $nestLevel == 0){
    $inlineText = $self->html->escape($inlineText);
  }

  $inlineText =~ s|$REGEXP_ITALIC
                  |$self->html->inlineElement(
                    $self->config->html->{element}->{italic},
                    $self->_parseInlineText($1, $nestLevel + 1, $footnoteRef),
                    ())|gex; #'i'
  $inlineText =~ s|$REGEXP_BOLD
                  |$self->html->inlineElement(
                    $self->config->html->{element}->{bold},
                    $self->_parseInlineText($1, $nestLevel + 1, $footnoteRef),
                    ())|gex; #'b'
  $inlineText =~ s|$REGEXP_INSERT
                  |$self->html->inlineElement(
                    $self->config->html->{element}->{ins},
                    $self->_parseInlineText($1, $nestLevel + 1, $footnoteRef),
                    ())|gex; #'u'
  $inlineText =~ s|$REGEXP_DELETE
                  |$self->html->inlineElement(
                    $self->config->html->{element}->{del},
                    $self->_parseInlineText($1, $nestLevel + 1, $footnoteRef),
                    ())|gex; #'s'

  # ����饤������ҥ�٥뤬0�ΤȤ�������󥯥��󥫡�������Ԥ�
  if(!defined($nestLevel) || $nestLevel == 0){
    # google, keyword�ʳ�
    $inlineText =~ s!
      \[\[
        ((.+?)(?::|\&gt;))?
          (
            (mailto|http|https|ftp|ASIN|ISBN|asin|isbn|anchor):([^\x00-\x20()<>\x7F-\xFF])*
            )
            \]\]
              !$self->anchorElement($3, $2)!gexi;
    # google��keyword�ξ��
    $inlineText =~ s!
      \[\[
        ((.+?)(?::|\&gt;))?
          (
            (google|keyword|anchor|wikipedia):[^\]]+
            )
            \]\]!$self->anchorElement($3, $2)!gexi;
    # keyword�ξ��
    $inlineText =~ s!\[\[(.+)\]\]
                    !$self->anchorElement($self->config->html->{default_keyword} . ':'. $1, '', ())!gexi;
  }
  $inlineText =~ s|~$|<br />|g;
  $inlineText =~ s|&amp;br;|<br />|gi;
  $inlineText =~ s|($REGEXP_PLUGIN)|$self->_parseInlinePlugin($1, $nestLevel)|gex;
  $inlineText =~ s|&amp;\#([0-9A-Fa-f]+);|&\#$1;|gi;
  $inlineText =~ s|&amp;([A-z]+);|&$1;|gi;
  # ����饤������ҥ�٥뤬0�ΤȤ���������������Ԥ�
  if(/$REGEXP_FOOTNOTE/ && !(defined($nestLevel) && $nestLevel != 0)){
    $inlineText =~ s|($REGEXP_FOOTNOTE)|$self->_parseInlineFootnote($1, $footnoteRef)|gex;
  }
  return $inlineText;
}

sub _parseInlineFootnote{
  my $self = shift;
  my ($inlineText, $footnoteRef) = @_;

  if($inlineText =~ /^\(\((.+)\)\)$/ ){
      $inlineText = $self->formatFootnoteAnchor($self->addFootnoteList(\@$footnoteRef, '', $1));
  }
  return $inlineText;
}

sub _parseInlinePlugin{
  my $self = shift;
  my ($inlineText, $nestLevel) = @_;
  if($inlineText =~ /^&amp;(\w+)\((.+)\);$/ ){
    return $self->_parseInlineFunction($1, $2,'', $nestLevel + 1);
  }
  elsif($inlineText =~ /^&amp;(\w+)\(([^){}]+?)\){(.+)};$/ ){
    return $self->_parseInlineFunction($1, $2, $3, $nestLevel + 1);
  }
  else{
    return $inlineText;
  }
}

sub _parseInlineFunction{
  my $self = shift;
  my ($localFuncName, $localFuncParam, $localInlineText, $localInlineNestLv) = @_;
  # Color
  if($localFuncName =~ /color/){
    my ($localForeColor, $localBackColor) = split(/\,/, $localFuncParam);
    my $localSpanStyle = '';
    $localSpanStyle = qq(color:${localForeColor};);
    if(defined($localBackColor) &&  $localBackColor ne ''){
      $localSpanStyle = $localSpanStyle . qq(background-color:${localBackColor};);
    }
    return $self->html->inlineElement('span', $self->_parseInlineText($localInlineText, $localInlineNestLv + 1),
                                      ('style'=> ${localSpanStyle})
                                      );
  }
  # Size
  elsif($localFuncName =~ /size/){
    return $self->html->inlineElement('span', $self->_parseInlineText($localInlineText, $localInlineNestLv + 1),
                                      ('style'=>"font-size:${localFuncParam}px")
                                      );
  }
  # ref
  elsif($localFuncName =~ /ref/){
    # ����޶��ڤ꤬�����
    if($localFuncParam =~ /^([^,]+)(,.+)$/){
      return $self->_parseRef($self->anchorElement($1, ''), $2);
    }
    else{
      return $self->anchorElement($localFuncParam, '');
    }
  }
  # ruby
  elsif($localFuncName =~ /ruby/){
    return $self->html->ruby($localFuncParam, $self->_parseInlineText($localInlineText, $localInlineNestLv + 1));
  }
  # aname
  elsif($localFuncName =~ /aname/){
    $localFuncParam =~ s/(\W)/'%' . unpack('H2', $1)/eg;
    my %attr = (
      'id'  => $localFuncParam,
      'name'=> $localFuncParam,
      );
    if($localInlineText ne ''){
      return $self->html->a($self->{mt}{'permalink'} . "#${localFuncParam}", $self->_parseInlineText($localInlineText, $localInlineNestLv + 1), %attr);
    }
    else{
      return $self->html->a($self->{mt}{'permalink'} . "#${localFuncParam}",  '', %attr);
    }
  }
  # verb
  elsif($localFuncName =~ /verb/){
    return $self->html->unescape($localFuncParam);
  }
  # style
  elsif($localFuncName =~ /style/){
    my %attr = (
      'style'  => $localFuncParam,
      );
    return $self->_parseInlineText('span', $self->_parseInlineText($localInlineText, $localInlineNestLv + 1), %attr);
  }
}

sub _parseRef{
  my $self = shift;
  my ($localAnchorString, $localRefParam) = @_;
  if($localRefParam =~ /,(left|right|center),?/){
    my $localAlign = $1;
    if($localRefParam =~ /,around,?/){
      if($localAlign eq 'center'){
        $localAlign = 'left';
      }
      $localAnchorString = qq(<div style="float:${localAlign};">${localAnchorString}</div>);
    }
    else{
      $localAnchorString = qq(<div style="text-align:${localAlign};">${localAnchorString}</div>);
    }
  }
  if($localRefParam =~ /,(wrap),?/){
    $localAnchorString =~ s|<img |<img border=\"1\" |gi;
  }
  if($localRefParam =~ /,(nowrap),?/){      # donothing
  }
  if($localRefParam =~ /,(nolink),?/){
    $localAnchorString =~ s|<a.+>(.+)</a>|$1|gi;
  }
  if($localRefParam =~ /,([^,]+)$/){
    my $localAltString = $1;
    #if(grep($_ eq $localAltString, 'around','left','right','center','wrap','nowrap','nolink','noembed') == 0){
    #  $localAnchorString =~ s|alt=\"[^\"]*\"|alt=\"${localAltString}\"|gi;
    #}
  }
  if($localRefParam =~ /,(noembed),?/){
    $localAnchorString =~ s!(<img.*alt=\"([^"]*)\".*>)!$2!gi; #"
  }
  return $localAnchorString;
}

1;
