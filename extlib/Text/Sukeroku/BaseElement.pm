package Text::Sukeroku::BaseElement;

use strict;
use Carp qw(croak);

sub new{
  my $class = shift;
  my $param = shift if (@_);

  #init
  $param->{counter}  = {
    level1   => 0,
    level2   => 0,
    level3   => 0,
  };
  bless $param, $class;
}

sub config{
  my $self  = shift;
  return $self->{config};
}

sub singleElement{
  my $self  = shift;
  my ($name, %attr)  = @_;
  my $answer = "";
  $answer = $name;
  while(my ($attrName, $attrValue) = each (%attr)){
    unless(defined($attrValue)){
      $attrValue = "";
    }
    $answer .= qq( $attrName="$attrValue");
  }
  if($self->config->html->{flavor} eq 'xhtml'){
    $answer .= qq( /);
  }
  return qq(<$answer>) . (($self->config->html->{break}) ? "\n" : '');
}

sub openElement{
  my $self  = shift;
  my ($name, %attr)  = @_;
  my $answer = $name;
  while(my ($attrName, $attrValue) = each (%attr)){
    $answer .= qq( $attrName="$attrValue");
  }
  return qq(<$answer>);
}
sub closeElement{
  my $self  = shift;
  my ($name)  = @_;
  my $answer = $name;
  return qq(</$answer>)  . (($self->{break}) ? "\n" : '');
}
sub inlineElement{
  my $self  = shift;
  my ($name, $inline, %attr)  = @_;
  return $self->openElement($name, %attr) . $inline . $self->closeElement($name);
}

sub escape {
  my $self  = shift;
  my $s = shift;
  $s =~ s|\r\n|\n|g;
  $s =~ s|\&|&amp;|g;
  $s =~ s|<|&lt;|g;
  $s =~ s|>|&gt;|g;
  $s =~ s|\"|&quot;|g;
  return $s;
}
sub unescape {
  my $self  = shift;
  my $s = shift;
  # $s =~ s|\n|\r\n|g;
  $s =~ s|\&amp;|\&|g;
  $s =~ s|\&lt;|\<|g;
  $s =~ s|\&gt;|\>|g;
  $s =~ s|\&quot;|\"|g;
  return $s;
}

##
##
##
##

sub br{
  my $self  = shift;
  my %attr  = @_;
  return $self->singleElement('br', %attr);
}
sub hr{
  my $self  = shift;
  my %attr  = @_;
  return $self->singleElement('hr', %attr);
}

sub a{
  my $self  = shift;
  my ($href, $inline, %attr)  = @_;
  $attr{'href'} = $href;
  if(!defined($inline) && $inline eq '' ){
    if(!defined($attr{'id'}) || $attr{'id'} eq ''){
      $inline = $href;
    }
  }
  my $target = ($self->config->html->{a_target} ne '') ? $self->config->html->{a_target} : '_self';
  if($self->config->html->{a_target} ne '_self' && $self->config->html->{flavor} eq 'xhtml'){
    $attr{'onclick'} = "window.open(this.href); return false;";
  }
  elsif($attr{'target'} eq ''){
    $attr{'target'} = $target;
  }

  if(defined($attr{'name'})){
    if($attr{'name'} ne '' && $self->config->html->{flavor} eq 'xhtml'){
      $attr{'id'} = $attr{'name'};
      delete $attr{'name'};
    }
  }

  if($self->config->html->{flavor} eq 'xhtml'){
    #$attr{'href'} =~ s|\&|\&amp;|g; 
  }
  return $self->inlineElement('a', $inline, %attr);
}

sub img{
  my $self  = shift;
  my ($src, $alt, %attr)  = @_;
  $attr{'src'}   = $src;
  $attr{'alt'}   = $alt;
  $attr{'title'} = $alt if ($attr{'title'} eq '') ;
  return $self->singleElement('img', %attr);
}

sub ruby{
  my $self    = shift;
  my ($text, $rubyText, %param) = @_;

  return $self->inlineElement(
    'ruby',
    $self->inlineElement('rb', $text, ()).
    $self->inlineElement('rp', '(',       ()).
    $self->inlineElement('rt', $rubyText, ()).
    $self->inlineElement('rp', ')',       ()),
    %param);
}

sub comment{
  my $self  = shift;
  my ($comment)  = @_;
  return qq(<!-- $comment -->);
}

1;