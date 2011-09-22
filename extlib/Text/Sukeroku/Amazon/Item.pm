package Text::Sukeroku::Amazon::Item;

use strict;
use XML::Simple;

####------------------------------------------------------------------------
#### コンストラクタメソッド
####------------------------------------------------------------------------
sub new {
  my($class, %options) = @_;

  if(!exists $options{charset}) {
    $options{charset} = "euc";
  }
  
  my $self = {
    properties => {status => 0},
    charset    => $options{charset}
  };
  bless $self, $class;
  $self->init($options{Item});
  return $self;
}

sub init{
  my($self, $item) = @_;
  $self->initItem($item);
}

sub initItem{
  my($self, $item) = @_;

  if($item->{ItemAttributes}->{ProductGroup}){
    $self->{properties}->{ProductGroup} =  $item->{ItemAttributes}->{ProductGroup};
  }

  if($item->{DetailPageURL}){
    $self->{properties}->{DetailPageURL} =  $item->{DetailPageURL};
  }

  if($item->{ASIN}){
    $self->{properties}->{ASIN} =  $item->{ASIN};
  }
  if($item->{SalesRank}){
    $self->{properties}->{SalesRank} =  $item->{SalesRank};
  }
  if($item->{SmallImage}){
    my $ptr = $item->{SmallImage};
    $self->{properties}->{SmallImage} =  {
      URL    => $ptr->{URL},
      Height => $ptr->{Height},
      Width  => $ptr->{Width},
    };
  }
  if($item->{MediumImage}){
    my $ptr = $item->{MediumImage};
    $self->{properties}->{MediumImage} =  {
      URL    => $ptr->{URL},
      Height => $ptr->{Height},
      Width  => $ptr->{Width},
    };
  }
  if($item->{LargeImage}){
    my $ptr = $item->{LargeImage};
    $self->{properties}->{LargeImage} =  {
      URL    => $ptr->{URL},
      Height => $ptr->{Height},
      Width  => $ptr->{Width},
    };
  }

  if($item->{ItemAttributes}){
    $self->initItemAttributes($item->{ItemAttributes});
  }
  if($item->{Offers}){
    $self->initOffers($item->{Offers});
  }
  if($item->{CustomerReviews}){
    $self->{properties}->{CustomerReviews} =  $item->{CustomerReviews};
  }
  if($item->{EditorialReviews}){
    $self->{properties}->{EditorialReview} =  $item->{EditorialReviews}->{EditorialReview};
  }
  if($item->{Tracks}){
    #$self->initItemAttributes($item->{ItemAttributes});
  }
  
}

sub initItemAttributes{
  my($self, $top) = @_;

  if($top->{Author}){
    $self->{properties}->{Author} =  $top->{Author};
  }
  if($top->{Artist}){
    $self->{properties}->{Artist} =  $top->{Artist};
  }
  if($top->{Actor}){
    $self->{properties}->{Actor} =  $top->{Actor};
  }
  if($top->{Director}){
    $self->{properties}->{Director} =  $top->{Director};
  }
  if($top->{Creator}){
    $self->{properties}->{Creator} = {
      role => $self->{properties}->{Creator}->{Role},
      name => $self->{properties}->{Creator}->{content},
    }
  }
  if($top->{ISBN}){
    $self->{properties}->{ISBN} =  $top->{ISBN};
  }

  if($top->{ListPrice}){
    my $ptr = $top->{ListPrice};
    $self->{properties}->{ListPrice} =  {
      Amount          => $ptr->{Amount},
      CurrencyCode    => $ptr->{CurrencyCode},
      FormattedPrice  => $ptr->{FormattedPrice},
    };
  }

  if($top->{Label}){
    $self->{properties}->{Label} =  $top->{Label};
  }
  if($top->{Publisher}){
    $self->{properties}->{Publisher} =  $top->{Publisher};
  }
  if($top->{Manufacturer}){
    $self->{properties}->{Manufacturer} =  $top->{Manufacturer};
  }
  
  if($top->{NumberOfItems}){
    $self->{properties}->{NumberOfItems} =  $top->{NumberOfItems};
  }
  if($top->{NumberOfPages}){
    $self->{properties}->{NumberOfPages} =  $top->{NumberOfPages};
  }
  if($top->{NumberOfDiscs}){
    $self->{properties}->{NumberOfDiscs} =  $top->{NumberOfDiscs};
  }
  if($top->{NumberOfTracks}){
    $self->{properties}->{NumberOfTracks} =  $top->{NumberOfTracks};
  }
  if($top->{Platform}){
    $self->{properties}->{Platform} =  $top->{Platform};
  }

  if($top->{PublicationDate} || $top->{ReleaseDate}){
    if($top->{PublicationDate}){
      $self->{properties}->{ReleaseDate} =  $top->{PublicationDate};
    }
    else{
      $self->{properties}->{ReleaseDate} =  $top->{ReleaseDate};
    }
  }
  if($top->{Title}){
    $self->{properties}->{Title} =  $top->{Title};
  }
   
}

sub initOffers{
  my($self, $top) = @_;
  if($top->{Offer}->{OfferListing}->{Price}){
    my $ptr = $top->{Offer}->{OfferListing}->{Price};
    $self->{properties}->{Price} =  {
      Amount          => $ptr->{Amount},
      CurrencyCode    => $ptr->{CurrencyCode},
      FormattedPrice  => $ptr->{FormattedPrice},
    };
  }
  if($top->{Offer}->{OfferListing}->{Availability}){
    $self->{properties}->{Availability} =  $top->{Offer}->{OfferListing}->{Availability};
  }
  
}

####------------------------------------------------------------------------
#### ネストしたXMLエレメントを配列にまとめる
####------------------------------------------------------------------------
sub _toArray(){
  # パラメータの取得
  my ($base, $child) = @_;
  my @answer;
  if (ref($base->{$child}) eq 'ARRAY') {
    push(@answer,@{$base->{$child}});
  }
  elsif($base->{$child}){
    push(@answer,$base->{$child});
  }
  return @answer;
}
1;
