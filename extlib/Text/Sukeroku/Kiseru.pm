package Text::Sukeroku::Kiseru;
##############################################################################
## パラメータ定義クラス（行儀悪い方法・・・つーかOOPじゃないよね orz）      ##
##############################################################################
use strict;
use Carp qw(croak);

sub html{{
    ## HTMLの要素出力スタイル
    flavor => 'xhtml',
    ## リンク時に画像ファイルなら自動展開(展開する…1, 展開しない…0)
    linkAutoImage  => 1,
    ## 論理行末は強制的に<br />を挟む。(対応する…1, 対応しない…0)
    convertLineBreak  => 0,
    ## リンク時のtarget指定
    ## ・同じウィンドウに展開する…… '_self'
    ## ・新しいウィンドウに展開する… '_blank'
    a_target      => '_blank',
    ## 強調表示に使うHTML要素の指定
    element => {
      bold   => 'strong',
      italic => 'em',
      del    => 'del',
      ins    => 'ins',
    },
    ## [[...]]の指定（）
    default_keyword => 'google',
};}

sub heading{{
    # 見出しの先頭につける文字列
    symbol1        => '&#9632;', #■
    symbol2        => '&#9632;', #■
    symbol3        => '&#9632;', #■
    # 見出しリンクアンカーの種類
    #   ・見出し文字列から生成………………… 1
    #   ・見出し番号（章・節・項）から生成… 0
    anchorType     => 1,
};}

sub footnote{{
    ## 脚注の先頭につける文字列
    symbol1       => '&#8224;',
    symbol2       => '&#8225;', # 未対応
    symbol3       => '*',       # 未対応
    ## 脚注表示に使うHTML要素と属性の指定
    html =>{
      tagList   => 'ul',
      classList => 'footnote', 
      tagItem   => 'li',
      classItem => 'footnote',
      tagRoot   => 'span',
      classRoot => 'footnote',  
    },
};}

sub amazon{{
  ## AmazonアソシエイトId
  ## (※)契約されていない場合は空欄''にしておいてください。
  aid      => 'hsjjp-22',
  ## Amazon Web Services(AWS) Developers' Token
  ## (※)契約されていない場合は空欄''にしておいてください。
  token    => '0Q00TC89ZRCXRJ390YR2',
  ## Amazonの書影画像が存在しない場合の代替画像のアドレス
  altImage => '/works/comingsoon.gif',
  ## ASIN:XXXXXXXXXX:detail時の強制utf8_decodeのフラグ
  ## (※)detail, async使用時に文字化けが発生する場合
  ##     (lolipopなど)では1にしてください
  forceUtf8FlagDecode => 0,
};}
sub amazon_detail_tmpl{
  return << "END_OF_TMPL";
<div class="asin-detail">
<TMPL_IF NAME="FALSE"><TMPL_VAR NAME="ImageUrlSmall"><TMPL_VAR NAME="AssociateTag"><TMPL_VAR NAME="SubscriptionId"></TMPL_IF><a href="<TMPL_VAR NAME="DetailPageURL">"><img src="<TMPL_IF NAME="ImageUrlMedium"><TMPL_VAR NAME="ImageUrlMedium"><TMPL_ELSE><TMPL_VAR NAME="ImageUrlAlt"></TMPL_IF>" alt="<TMPL_VAR NAME="ProductName">" title="<TMPL_VAR NAME="ProductName">" /></a>
<p><a href="<TMPL_VAR NAME="DetailPageURL">"><TMPL_VAR NAME="ProductName"></a></p>
<ul>
<TMPL_IF NAME="FALSE">
  <li>ASIN：<TMPL_VAR NAME="Asin"></li>
</TMPL_IF><TMPL_IF NAME="FALSE">
  <li>ISBN：<TMPL_VAR NAME="ISBN"></li>
</TMPL_IF><TMPL_IF NAME="FALSE">
  <li>ProductGroup：<TMPL_VAR NAME="ProductGroup"></li>
</TMPL_IF><TMPL_IF NAME="Author">
  <li>作者：<TMPL_VAR NAME="Author"></li>
</TMPL_IF><TMPL_IF NAME="Artist">
  <li>アーティスト：<TMPL_VAR NAME="Artist"></li>
</TMPL_IF><TMPL_IF NAME="Artist">
  <li>アーティスト：<TMPL_VAR NAME="Artist"></li>
</TMPL_IF><TMPL_IF NAME="Director">
  <li>監督：<TMPL_VAR NAME="Director"></li>
</TMPL_IF><TMPL_IF NAME="Manufacturer">
  <li>出版社・メーカー：<TMPL_VAR NAME="Manufacturer"></li>
</TMPL_IF><TMPL_IF NAME="Publisher">
  <li>出版社・メーカー：<TMPL_VAR NAME="Publisher"></li>
</TMPL_IF><TMPL_IF NAME="Label">
  <li>出版社・メーカー：<TMPL_VAR NAME="Label"></li>
</TMPL_IF><TMPL_IF NAME="ReleaseDate">
  <li>発売(予定)日：<TMPL_VAR NAME="ReleaseDate"></li>
</TMPL_IF><TMPL_IF NAME="Availability">
  <li>入手可能状態：<TMPL_VAR NAME="Availability"></li>
</TMPL_IF><TMPL_IF NAME="Media">
  <li>メディア：<TMPL_VAR NAME="Media"></li>
</TMPL_IF><TMPL_IF NAME="Platform">
  <li>プラットフォーム：<TMPL_VAR NAME="Platform"></li>
</TMPL_IF><TMPL_IF NAME="Price">
  <li>価格：<TMPL_VAR NAME="Price"></li>
</TMPL_IF><TMPL_IF NAME="ListPrice">
  <li>定価：<TMPL_VAR NAME="ListPrice"></li>
</TMPL_IF><TMPL_IF NAME="SalesRank">
  <li>Amazon内売上順位：<TMPL_VAR NAME="SalesRank"></li>
</TMPL_IF><TMPL_IF NAME="CustomerReviews">
  <li>評価：<TMPL_VAR NAME="CustomerReviews"></li>
</TMPL_IF>
</ul><!--
<form method="post" action="http://www.amazon.co.jp/o/dt/assoc/handle-buy-box=<TMPL_VAR NAME="Asin">" target="_blank">
  <input type="hidden" name="asin.<TMPL_VAR NAME="Asin">" value="1" />
  <input type="hidden" name="tag-value"    value="<TMPL_VAR NAME="AssociateTag">" />
  <input type="hidden" name="tag_value"    value="<TMPL_VAR NAME="AssociateTag">" />
  <input type="hidden" name="dev-tag-value" value="<TMPL_VAR NAME="SubscriptionId">" />
  <input type="submit" name="submit.add-to-cart" value="カートに入れる" />
  <input type="submit" name="submit.add-to-registry.wishlist" value="ウィッシュリストに入れる" />
</form>-->
</div>
END_OF_TMPL
}
sub amazon_async_tmpl{
  return << "END_OF_TMPL";
<script src="/blog/asin_js.cgi?asin=<TMPL_VAR NAME="Asin">">
</script>
END_OF_TMPL
}

sub pukiwiki{{
    ## コメント内逐語出力モードの利用
    ##   ・逐語出力する… 1, 逐語出力しない… 0
    verbatimEnabled         => 1,
    verbatimHardOpenRegexp  => "^\/\/\/\/",
    verbatimHardCloseRegexp => "^\/\/\/\/",
    verbatimSoftOpenRegexp  => "^\/\/\/",
    verbatimSoftCloseRegexp => "^\/\/\/",
    ## エントリの末尾に<div style="margin:0px;clear:both;line-height:0%;"></div>
    ##   を出力する
    ##  ・出力する… 1, 出力しない… 0
    bottomClearOutput => 1,
};}

sub new{
  my $class  = shift;
  my $param  = shift if (@_);
  $param->{dummy}   = '';
  bless $param,$class;
}
1;
