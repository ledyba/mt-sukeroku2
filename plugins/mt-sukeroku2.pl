#!/usr/bin/perl
##----------------------------------------------------------------------
## mt-sukeroku2.pl
## Copyright(C)DonaDona (KITAO Masato)
##----------------------------------------------------------------------

package MT::Plugins::Sukeroku2;

use vars qw($VERSION);
$VERSION = 0.03;

use strict;
no strict 'refs';
use Carp qw(croak);
use Jcode;
use Text::Sukeroku::Agemaki;

use MT;
use MT::Blog;
use MT::ConfigMgr;
use MT::Entry;
use MT::Template::Context;

##----------------------------------------------------------------------
## YukiWiki�饤���ե����ޥå�
##----------------------------------------------------------------------
MT->add_text_filter(sukeroku2_yukiwiki => {
  label => 'Sukeroku2(YukiWikiLike)',
  docs => 'http://hsj.jp/works/archives/000318.html',
  on_format => sub {
    my ($text, $ctx) = @_;
    return &formatCore('yukiwiki', \$text, \$ctx);
  },
});
##----------------------------------------------------------------------
## PukiWiki�饤���ե����ޥå�
##----------------------------------------------------------------------
MT->add_text_filter(sukeroku2_pukiwiki => {
  label => 'Sukeroku2(PukiWikiLike)',
  docs => 'http://hsj.jp/works/archives/000317.html',
  on_format => sub {
    my ($text, $ctx) = @_;
    return &formatCore('pukiwiki', \$text, \$ctx);
  },
});
##----------------------------------------------------------------------
## �ϤƤʥ������꡼�饤���ե����ޥå�
##----------------------------------------------------------------------
MT->add_text_filter(sukeroku2_hatena => {
  label => 'Sukeroku2(HatenaDiaryLike)',
  docs => 'http://hsj.jp/works/archives/000324.html',
  on_format => sub {
    my ($text, $ctx) = @_;
    return &formatCore('hatena', \$text, \$ctx);
  },
});

##----------------------------------------------------------------------
## ������ʬ�ĤȤ��äƤ�Text::Sukeroku���ꤲ�Ƥ�����Ǥ���
##----------------------------------------------------------------------
sub formatCore{
  my ($format, $refText, $refCtx) = @_;
  if($$refText ne ''){
    my $agemaki = Text::Sukeroku::Agemaki->new();
    my $text    = $$refText;

    # ����饯�����åȤμ��� (from aws.pl)
    my $cfg     = MT::ConfigMgr->instance;
    my $charset = {'Shift_JIS'   =>'sjis',
                   'ISO-2022-JP' =>'jis',
                   'EUC-JP'      => 'euc',
                   'UTF-8'       =>'utf8'}->{$cfg->PublishCharset} || 'utf8';
    
    # ����ʸ�����åȤ˥��󥳡���
    if($charset ne 'utf8'){
      $text = jcode($text, $charset)->utf8;
    }

    # �ե����ޥå�Factory
    my $obj = $agemaki->create($format, $text);
    
    ## MT::Context�μ����Ϥ� --��������
    if(defined($$refCtx) && (ref($$refCtx) eq 'MT::Template::Context')){
      # ����ȥ꡼��Permalink��ID�����
      # �ƥ����ȤΤɤΥѡ��Ȥ���Ƚ�ꡣ(��ʸ���ɵ�����ά)
      my $entry = $$refCtx->stash('entry');
      if ($entry && $entry->id) {
        my $text_part = ($text eq $entry->text)      ? 'text'      :
                        ($text eq $entry->text_more) ? 'text_more' :
                        ($text eq $entry->excerpt)   ? 'excerpt'   : '';
        $obj->{mt}{'imported'}  = 1;
        $obj->{mt}{'permalink'} = $entry->permalink;
        $obj->{mt}{'entry_id'}  = $entry->id;
        $obj->{mt}{'text_part'} = $text_part;
      }
    }
    $obj->{mt}{'charset'} = $charset;
    ## MT::Context�μ����Ϥ� --�����ޤ�
    
    # �ե����ޥå����Ѵ��������󥳡���
    $text = $obj->formatText();
    if(Jcode::getcode($text) ne $charset){
      Jcode::convert(\$text,$charset);
    }
    return $text;
  }
  else{
    return "";
  }
}
1;
