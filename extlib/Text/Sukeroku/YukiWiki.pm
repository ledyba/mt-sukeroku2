package Text::Sukeroku::YukiWiki;
##----------------------------------------------------------------------
## YukiWiki���ƥ����ȥե����ޥå�
##       http://hsj.jp/works/archives/000318.html
##----------------------------------------------------------------------
use strict;
use Carp qw(croak);
#use base qw(Text::Sukeroku::BaseFormat);
use vars qw(@ISA);
require Text::Sukeroku::BaseFormat;
push @ISA, 'Text::Sukeroku::BaseFormat';

sub init{
  my $self = shift;
  $self->SUPER::init();
}

## ����ɽ�������
my $REGEXP_ITALIC = qq('''([^']+?)'''); #'
my $REGEXP_BOLD   = qq(''([^']+?)''); #'
my $REGEXP_LINK   = qq((mailto|http|https|ftp):([^\x00-\x20()<>\x7F-\xFF])*);
my $REGEXP_PLUGIN = '\&amp;(\w+)\(((([^()]*(\([^()]*\))?)*)*)\)';

sub formatText {
  my $self    = shift;

  # �����оݹԤ�����
  my (@lines) = split(/\r?\n/, $self->{source});
  
  # tag�Υ����å�������
  my (@saved, @result);
  
  # �С��٥�����⡼�ɡ�0=�ʤ���1=soft��2=hard��
  my $verbatimMode = 0;

  # ��Ԥ��ĥե����ޥåȽ����򤹤�
  foreach (@lines) {
    # ������\n�����
    chomp;

    # �С��٥�����⡼��
    if($verbatimMode >= 1){
      my $localVerbatimLevel = $verbatimMode + 1;
      if(/^(-{$localVerbatimLevel})\)$/){
        push(@result, splice(@saved));
        $verbatimMode = 0;
      }
      else{
        ($verbatimMode == 1) ? push(@result, $_)
                                     : push(@result, $self->html->escape($_));
      }
      next;
    }
    # ���Ф�
    if (/^(\*{1,3})(.*)/) {
      push(@result, splice(@saved), $self->html->heading(length($1), $self->_parseInlineText($2, 0), ()));
    }
    # �С��٥�����⡼��
    elsif (/^(-{2,3})\($/) {
      $verbatimMode = length($1) - 1;
      $self->backPush('pre', 1, \@saved, \@result, ());
      next;
    }
    # ��ʿ��
    elsif (/^----/) {
      push(@result, splice(@saved), $self->html->hr(()));
    }
    # �ꥹ��
    elsif (/^(-{1,3})(.*)/) {
      $self->backPush('ul', length($1), \@saved, \@result, ());
      push(@result, $self->html->inlineElement('li', $self->_parseInlineText($2, 0), ()));
    }
    # ����ꥹ��
    elsif (/^:([^:]*):(.*)/) {
      $self->backPush('dl', 1, \@saved, \@result, ());
      if(defined($1) && $1 ne ''){
        push(@result, $self->html->inlineElement('dt', $self->_parseInlineText($1, 0), ()));
      }
      push(@result, $self->html->inlineElement('dd', $self->_parseInlineText($2, 0), ()));
    }
    # ����ʸ
    elsif (/^(>{1,3})(.*)/) {
      $self->backPush('blockquote', length($1), \@saved, \@result, ());
      push(@result, $self->_parseInlineText($2, 0));
      if($self->config->html->{convertLineBreak}){
        push(@result, $self->html->br(()));
      }
    }
    # ����
    elsif (/^$/) {
      push(@result, splice(@saved));
      unshift(@saved, $self->html->closeElement('p'));
      push(@result, $self->html->openElement('p',()));
    }
    # �����Ѥߥƥ�����
    elsif (/^\s(.*)$/) {
      $self->backPush('pre', 1, \@saved, \@result, ());
      push(@result, $self->html->escape($1)); # Not &$func_inline, but &escape
    }
    # YukiWiki����ޤ뤴�Ȱ��ѡ�
    # This part is taken from Mr. Ohzaki's Perl Memo and Makio Tsukamoto's WalWiki.
    elsif (/^\,(.*?)[\x0D\x0A]*$/) {
      $self->backPush('table', 1, \@saved, \@result, ());
      my $tmp = "$1,";
      my @value = map {/^"(.*)"$/ ? scalar($_ = $1, s/""/"/g, $_) : $_} ($tmp =~ /("[^"]*(?:""[^"]*)*"|[^,]*),/g); # "
      my @align = map {(s/^\s+//) ? ((s/\s+$//) ? ' align="center"' : ' align="right"') : ''} @value;
      my @colspan = map {($_ eq '==') ? 0 : 1} @value;
      for (my $i = 0; $i < @value; $i++) {
        if ($colspan[$i]) {
          while ($i + $colspan[$i] < @value and $value[$i + $colspan[$i]] eq '==') {
            $colspan[$i]++;
          }
          $colspan[$i] = ($colspan[$i] > 1) ? sprintf(' colspan="%d"', $colspan[$i]) : '';
          $value[$i] = sprintf('<td%s%s>%s</td>', $align[$i], $colspan[$i], $self->_parseInlineText($value[$i], 0));
        }
        else {
          $value[$i] = '';
        }
      }
      push(@result, join('', $self->html->openElement('tr',()), @value, $self->html->closeElement('tr')));
    }
    else {
      push(@result, $self->_parseInlineText($_, 0));
      if($self->config->html->{convertLineBreak}){
        push(@result, $self->html->br(()));
      }
    }
    
  }
  # �����å��򤹤٤Ʋ����Ф������٤Ʋ���ʸ���򶴤߹��߽��ϡ�
  push(@result, splice(@saved));
  return join("\n", @result);
}

sub _parseInlineText{
  my $self = shift;
  my ($inlineText, $nestLevel) = @_;
  $inlineText = $self->html->escape($inlineText) if($nestLevel == 0);
  $inlineText =~ s!$REGEXP_ITALIC
                  !$self->html->inlineElement(
                    $self->config->html->{element}->{italic},
                    $self->_parseInlineText($1, $nestLevel + 1),
                    ())!gex; 
  $inlineText =~ s!$REGEXP_BOLD
                  !$self->html->inlineElement(
                    $self->config->html->{element}->{bold},
                    $self->_parseInlineText($1, $nestLevel + 1),
                    ())!gex; 
  $inlineText =~ s!(($REGEXP_LINK)|($REGEXP_PLUGIN))
                  !$self->_parseInlineAnchor($1)!gex;
  # keyword�ξ��
  $inlineText =~ s!\[\[(.+)\]\]
                  !$self->anchorElement($self->config->html->{default_keyword} . ':'. $1, $1, ())!gexi;
  return $inlineText;
}

sub _parseInlineAnchor {
  my $self = shift;
  my ($inlineText) = @_;
  if($inlineText =~ /^$REGEXP_LINK/i ){
    $inlineText = $self->anchorElement($inlineText, $inlineText);
  }
  elsif($inlineText =~ /^$REGEXP_PLUGIN/){
    my $pluginName  = lc($1);
    my @pluginParam = split(/,/,$2);
    # plugin ����
    $inlineText =
      ($pluginName eq 'ruby')      ? $self->html->ruby($pluginParam[0], $pluginParam[1], ()) :
      ($pluginName eq 'link')      ? $self->html->a($pluginParam[1], $pluginParam[0],()) :
      ($pluginName eq 'wikipedia') ? $self->html->wikipedia($pluginParam[0],()) :
      ($pluginName eq 'keyword')   ? $self->html->hatenaKeyword($pluginParam[0],()) :
      ($pluginName eq 'amazon')    ? $self->html->asinStaticText($pluginParam[1], $pluginParam[0]) :
      ($pluginName eq 'amazon_detail')  ? $self->html->asinDetail($pluginParam[0], ()) :
      ($pluginName eq 'amazon_async')  ? $self->html->asinAsync($pluginParam[0], ()) :
      ($pluginName eq 'color')     ? $self->html->inlineElement(
        'span', $pluginParam[1], ('style' => "color:$pluginParam[0];")) :
      ($pluginName eq 'style')     ? $self->html->inlineElement(
          'span', $pluginParam[1], ('style' => "$pluginParam[0];")) :
      ($pluginName eq 'verb')    ? $self->html->unescape($pluginParam[0]) :$inlineText;
  }
  return $inlineText;
}

1;
