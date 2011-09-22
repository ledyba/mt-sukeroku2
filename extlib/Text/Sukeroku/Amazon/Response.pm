package Text::Sukeroku::Amazon::Response;

use strict;

use LWP::UserAgent;
use XML::Simple;
use Text::Sukeroku::Amazon::Item;

####------------------------------------------------------------------------
#### コンストラクタメソッド
####------------------------------------------------------------------------
sub new {
  my($class, %options) = @_;
  
  my $self = {
    status        => "",
    messages      => [],
    items         => [],
    rawdata       => "",
    total_results => undef,
    total_pages   => undef,
  };
  bless $self, $class;
  return $self;
}

sub message {
  my($self) = @_;
  return join(";",@{$self->{messages}});
}

sub is_success {
  my($self) = @_;
  return $self->{status} ? 1 : "";
}

sub is_error {
  my($self) = @_;
  return !$self->is_success();
}

sub push_item {
  my($self, $item) = @_;
  my $thisItem = Text::Sukeroku::Amazon::Item->new(Item => $item);
  push @{$self->{items}}, $thisItem;
}

1;
