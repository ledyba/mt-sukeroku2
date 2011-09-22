package Text::Sukeroku::HatenaDiary;
##############################################################################
## ■ はてなダイアリー風テキストフォーマット用サブルーチン                  ##
##       http://hsj.jp/works/archives/000324.html                           ##
##############################################################################
use strict;
no strict 'refs';
use Carp qw(croak);
#use base qw(Text::Sukeroku::BaseFormat);
use vars qw(@ISA);
require Text::Sukeroku::BaseFormat;
push @ISA, 'Text::Sukeroku::BaseFormat';

## 正規表現の定数
my $REGEXP_LINK   = '(?:(?:(?:http|https|ftp|mailto|google|anchor|keyword|wikipedia):)|(?:(?:ISBN|isbn|ASIN|asin):\w+(?::(?:image(?::\w+)|detail)?)?)|[^:])+';
my $REGEXP_FOOTNOTE = qr/\(\(.*?(?:(?:{$Text::Sukeroku::HatenaDiary::REGEXP_FOOTNOTE}).*)*?\)\)/;

sub init{
  my $self = shift;
  $self->SUPER::init();
}

sub formatText {
  my $self    = shift;
  my (@lines) = split(/\n/, $self->{source});
  
  # 論理行頭が>|で開始し、論理行末が|<で終了するまで 整形済みテキストの扱いとする
  my $modePreLevel = 0;
  # 論理行頭が>で開始し、論理行末が<で終了するまで<p></p>の囲み処理を行う
  my $modeParagraph = 1;
  # 論理行頭が><!--で開始し、論理行末が--><で終了するまで整形済みテキストの扱いとする
  my $modeDraft    = 0;
  
  # tagのスタックを初期化
  my (@saved, @result, @footnotes);
  # 処理上の最終行の状態と内容
  my $lastLine       = '';
  
  # 一行ずつフォーマット処理をする
  foreach (@lines) {
    # 末尾の\nを除去
    chomp;
    #
    # 下書きテキスト
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
      #最終処理行・状態の保存
      $lastLine       = $_;
      next;
    }
    #
    # 整形済みテキスト(開始)
    #
    elsif (/^>(\|{1,2})$/) {
      if($modePreLevel == 0){
        push(@result, splice(@saved));
        push(@result, $self->html->openElement('pre', ()));
        $modePreLevel = length($1);
      }
    }
    #
    # 整形済みテキスト(終了)
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
    # >|...>|の場合にフラグがONならばHTMLエスケープを実施する。
    # 以降の処理はスキップする（最終行の取得は行う）
    elsif($modePreLevel == 2){
      push(@result, $self->html->escape($_));
      $lastLine       = $_;
      next;
    }
    #
    # アンカー付き見出し 
    #
    elsif (/^(\*{1,3})([^\*]+)\*(.*)$/) {
      push(@result, splice(@saved), $self->html->heading(length($1), $self->_parseInlineText($3, \@footnotes), ('anchor' => $2)));
    }
    #
    # 見出し 
    #
    elsif (/^(\*{1,3})(.*)/) {
      push(@result, splice(@saved), $self->html->heading(length($1), $self->_parseInlineText($2, \@footnotes), ()));
    }
    #
    # リスト表示。
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
    # 用語定義
    #
    elsif(/^:($REGEXP_LINK)?:(.*)/){
      $self->backPush('dl', 1, \@saved, \@result, ());
      if(defined($1) && $1 ne ''){
        push(@result, $self->html->inlineElement('dt', $self->_parseInlineText($1, \@footnotes), ()));
      }
      push(@result, $self->html->inlineElement('dd', $self->_parseInlineText($2, \@footnotes), ()));
    }
    #
    # 引用
    #

    # 引用文
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
    # 表組み
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
      # スタックを吐き出す
      push(@result, splice(@saved));
      # 空白文字ではじまり、整形テキスト出力でないなら<p></p>付加
      if (/^ +/) {
        ($modeParagraph == 1 &&
         $modePreLevel != 1) ? push(@result, $self->html->inlineElement('p', $_, ()))
                             : push(@result, ($_));
      }
      else{
        my $inlineText = $_;

        # 論理行頭・行末の><の判定
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

        # インライン要素を展開
        $inlineText = $self->_parseInlineText($inlineText, \@footnotes);
        
        # <p>付加実施判定後、インライン処理。
        if($modeParagraph == 1 && $modePreLevel != 1){
          $inlineText = $self->html->inlineElement('p', $inlineText, ());
          $inlineText =~ s|(<p>.*)(<div.*?>.*</div>)(.*</p>)|$1</p>$2<p>$3|gisx;
          $inlineText =~ s|(<p>.*)(<script.*?>.*</script>)(.*</p>)|$1</p>$2<p>$3|gisx;
        }
        push(@result, $inlineText);

        # ><で終わっている場合は<p>付加フラグを立てる。
        if (/><$/) {
          $modeParagraph = 1;
        }
      }
    }
    #最終処理行・状態の保存
    $lastLine       = $_;
  }

  # スタックをすべて押し出し、脚注を挟み、すべて改行文字を挟み込み出力。
  push(@result, splice(@saved));
  if(@footnotes > 0){
    push(@result, $self->formatFootnoteList(\@footnotes));
  }
  return join("\n", @result);
}

sub _parseInlineText{
  my $self = shift;
  my ($inlineText, $footnoteRef) = @_;
  
  # ■ 自動リンク
  if(/(http|https|ftp|mailto|ISBN|isbn|ASIN|asin|google|anchor|keyword|wikipedia):.*/){
    # さまざまなパターンについて分岐
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
  # ■ キーワードリンク
  if(/\[\[([^\]]+)\]\]/){
    $inlineText =~ s!(
      (\[\[[^\]]+\]\])
      )!$self->_parseInlineAnchor($1)!gex;
  }
  # ■ 脚注
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
      # さまざまなパターンについて
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

  #[]URL[]…そのまま出力
  if($inlineText =~ /^\[\](.+)\[\]$/ ){
    $inlineText = $1;
  }
  #[[Words]]…キーワード扱い
  elsif($inlineText =~ /^\[\[(.+)\]\]$/ ){
    $inlineText = $self->anchorElement($self->config->html->{default_keyword} . ':'. $1, $1, ());
  }
  #[URL]…URLを切り出し
  elsif($inlineText =~ /^\[(.+):title=(.+)\]$/ ){
    $inlineText = $self->anchorElement($1, $2, ());
  }
  #[URL]…URLを切り出し
  elsif($inlineText =~ /^\[(.+)\]$/ ){
    $inlineText = $self->anchorElement($1, $1, ());
  }
  #[URL]…amazonを有効化
  elsif($inlineText =~ /^(src|href|cite)=[\'\"](.+)[\'\"]$/i ){
    my $localAttr = $1;
    my $localUrl  = $2;
    if($localUrl =~ /^(ISBN|isbn|ASIN|asin)/){
      my $localTempAnswer = $self->anchorElement($localUrl, $localUrl, ());
      $localTempAnswer =~ s|<a .*href=\"(.+)\".+|$1|x;
      $inlineText = qq(${localAttr}="${localTempAnswer}");
    }
    else{
      ;#$inlineText そのまま出力
    }
  }
  #URL…切り出し
  else{
    $inlineText = $self->anchorElement($inlineText, $inlineText, ());
  }
  return $inlineText;
};

1;
