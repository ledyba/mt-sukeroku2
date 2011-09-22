package Text::Sukeroku::Kiseru;
##############################################################################
## �ѥ�᡼��������饹�ʹԵ�������ˡ�������ġ���OOP����ʤ���� orz��      ##
##############################################################################
use strict;
use Carp qw(croak);

sub html{{
    ## HTML�����ǽ��ϥ�������
    flavor => 'xhtml',
    ## ��󥯻��˲����ե�����ʤ鼫ưŸ��(Ÿ�������1, Ÿ�����ʤ���0)
    linkAutoImage  => 1,
    ## ���������϶���Ū��<br />�򶴤ࡣ(�б������1, �б����ʤ���0)
    convertLineBreak  => 0,
    ## ��󥯻���target����
    ## ��Ʊ��������ɥ���Ÿ������ġ� '_self'
    ## ��������������ɥ���Ÿ������� '_blank'
    a_target      => '_blank',
    ## ��Ĵɽ���˻Ȥ�HTML���Ǥλ���
    element => {
      bold   => 'strong',
      italic => 'em',
      del    => 'del',
      ins    => 'ins',
    },
    ## [[...]]�λ���ʡ�
    default_keyword => 'google',
};}

sub heading{{
    # ���Ф�����Ƭ�ˤĤ���ʸ����
    symbol1        => '&#9632;', #��
    symbol2        => '&#9632;', #��
    symbol3        => '&#9632;', #��
    # ���Ф���󥯥��󥫡��μ���
    #   �����Ф�ʸ���󤫤������ġġġġġġ� 1
    #   �����Ф��ֹ�ʾϡ��ᡦ��ˤ��������� 0
    anchorType     => 1,
};}

sub footnote{{
    ## �������Ƭ�ˤĤ���ʸ����
    symbol1       => '&#8224;',
    symbol2       => '&#8225;', # ̤�б�
    symbol3       => '*',       # ̤�б�
    ## ����ɽ���˻Ȥ�HTML���Ǥ�°���λ���
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
  ## Amazon������������Id
  ## (��)���󤵤�Ƥ��ʤ����϶���''�ˤ��Ƥ����Ƥ���������
  aid      => 'hsjjp-22',
  ## Amazon Web Services(AWS) Developers' Token
  ## (��)���󤵤�Ƥ��ʤ����϶���''�ˤ��Ƥ����Ƥ���������
  token    => '0Q00TC89ZRCXRJ390YR2',
  ## Amazon�ν�Ʋ�����¸�ߤ��ʤ��������ز����Υ��ɥ쥹
  altImage => '/works/comingsoon.gif',
  ## ASIN:XXXXXXXXXX:detail���ζ���utf8_decode�Υե饰
  ## (��)detail, async���ѻ���ʸ��������ȯ��������
  ##     (lolipop�ʤ�)�Ǥ�1�ˤ��Ƥ�������
  forceUtf8FlagDecode => 0,
};}
sub amazon_detail_tmpl{
  return << "END_OF_TMPL";
<div class="asin-detail">
<TMPL_IF NAME="FALSE"><TMPL_VAR NAME="ImageUrlSmall"><TMPL_VAR NAME="AssociateTag"><TMPL_VAR NAME="SubscriptionId"></TMPL_IF><a href="<TMPL_VAR NAME="DetailPageURL">"><img src="<TMPL_IF NAME="ImageUrlMedium"><TMPL_VAR NAME="ImageUrlMedium"><TMPL_ELSE><TMPL_VAR NAME="ImageUrlAlt"></TMPL_IF>" alt="<TMPL_VAR NAME="ProductName">" title="<TMPL_VAR NAME="ProductName">" /></a>
<p><a href="<TMPL_VAR NAME="DetailPageURL">"><TMPL_VAR NAME="ProductName"></a></p>
<ul>
<TMPL_IF NAME="FALSE">
  <li>ASIN��<TMPL_VAR NAME="Asin"></li>
</TMPL_IF><TMPL_IF NAME="FALSE">
  <li>ISBN��<TMPL_VAR NAME="ISBN"></li>
</TMPL_IF><TMPL_IF NAME="FALSE">
  <li>ProductGroup��<TMPL_VAR NAME="ProductGroup"></li>
</TMPL_IF><TMPL_IF NAME="Author">
  <li>��ԡ�<TMPL_VAR NAME="Author"></li>
</TMPL_IF><TMPL_IF NAME="Artist">
  <li>�����ƥ����ȡ�<TMPL_VAR NAME="Artist"></li>
</TMPL_IF><TMPL_IF NAME="Artist">
  <li>�����ƥ����ȡ�<TMPL_VAR NAME="Artist"></li>
</TMPL_IF><TMPL_IF NAME="Director">
  <li>���ġ�<TMPL_VAR NAME="Director"></li>
</TMPL_IF><TMPL_IF NAME="Manufacturer">
  <li>���Ǽҡ��᡼������<TMPL_VAR NAME="Manufacturer"></li>
</TMPL_IF><TMPL_IF NAME="Publisher">
  <li>���Ǽҡ��᡼������<TMPL_VAR NAME="Publisher"></li>
</TMPL_IF><TMPL_IF NAME="Label">
  <li>���Ǽҡ��᡼������<TMPL_VAR NAME="Label"></li>
</TMPL_IF><TMPL_IF NAME="ReleaseDate">
  <li>ȯ��(ͽ��)����<TMPL_VAR NAME="ReleaseDate"></li>
</TMPL_IF><TMPL_IF NAME="Availability">
  <li>�����ǽ���֡�<TMPL_VAR NAME="Availability"></li>
</TMPL_IF><TMPL_IF NAME="Media">
  <li>��ǥ�����<TMPL_VAR NAME="Media"></li>
</TMPL_IF><TMPL_IF NAME="Platform">
  <li>�ץ�åȥե����ࡧ<TMPL_VAR NAME="Platform"></li>
</TMPL_IF><TMPL_IF NAME="Price">
  <li>���ʡ�<TMPL_VAR NAME="Price"></li>
</TMPL_IF><TMPL_IF NAME="ListPrice">
  <li>�����<TMPL_VAR NAME="ListPrice"></li>
</TMPL_IF><TMPL_IF NAME="SalesRank">
  <li>Amazon������̡�<TMPL_VAR NAME="SalesRank"></li>
</TMPL_IF><TMPL_IF NAME="CustomerReviews">
  <li>ɾ����<TMPL_VAR NAME="CustomerReviews"></li>
</TMPL_IF>
</ul><!--
<form method="post" action="http://www.amazon.co.jp/o/dt/assoc/handle-buy-box=<TMPL_VAR NAME="Asin">" target="_blank">
  <input type="hidden" name="asin.<TMPL_VAR NAME="Asin">" value="1" />
  <input type="hidden" name="tag-value"    value="<TMPL_VAR NAME="AssociateTag">" />
  <input type="hidden" name="tag_value"    value="<TMPL_VAR NAME="AssociateTag">" />
  <input type="hidden" name="dev-tag-value" value="<TMPL_VAR NAME="SubscriptionId">" />
  <input type="submit" name="submit.add-to-cart" value="�����Ȥ������" />
  <input type="submit" name="submit.add-to-registry.wishlist" value="�����å���ꥹ�Ȥ������" />
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
    ## �������������ϥ⡼�ɤ�����
    ##   �������Ϥ���� 1, �����Ϥ��ʤ��� 0
    verbatimEnabled         => 1,
    verbatimHardOpenRegexp  => "^\/\/\/\/",
    verbatimHardCloseRegexp => "^\/\/\/\/",
    verbatimSoftOpenRegexp  => "^\/\/\/",
    verbatimSoftCloseRegexp => "^\/\/\/",
    ## ����ȥ��������<div style="margin:0px;clear:both;line-height:0%;"></div>
    ##   ����Ϥ���
    ##  �����Ϥ���� 1, ���Ϥ��ʤ��� 0
    bottomClearOutput => 1,
};}

sub new{
  my $class  = shift;
  my $param  = shift if (@_);
  $param->{dummy}   = '';
  bless $param,$class;
}
1;
