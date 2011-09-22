package Text::Sukeroku::Amazon;

use strict;

use LWP::UserAgent;
use XML::Simple;
use Text::Sukeroku::Amazon::Response;

####------------------------------------------------------------------------
#### コンストラクタメソッド
####------------------------------------------------------------------------
sub new {
  my($class, %options) = @_;
  
  if(!exists $options{SubscriptionId}) {
    die "Paramter 'SubscriptionId' not defined";
  }
  if(!exists $options{AssociateTag}) {
    #die "Paramter 'AssociateTag' not defined";
    $options{AssociateTag} = "hsjjp-22";
  }
  
  my $self = {
    aws_base_url   => 'http://webservices.amazon.co.jp/onca/xml?Service=AWSECommerceService',
    ua             => LWP::UserAgent->new(),
    %options,
  };
  
  bless $self, $class;
}

####------------------------------------------------------------------------
#### REST形式のI/Oを担当するメソッド
####------------------------------------------------------------------------
sub request {
  my($self, $cache_key, @query) = @_;
  
  # 実行＆結果取得
  my $aws_url  =
    $self->{aws_base_url} . qq(&SubscriptionId=$self->{SubscriptionId}) .
    qq(\&AssociateTag=$self->{AssociateTag}\&) . join("&", @query);
  my $ua       = $self->{ua};
  if(exists $self->{http_proxy}){
    $ua->proxy('http', $self->{http_proxy});
  }

  my $http_res;
  my $res = Text::Sukeroku::Amazon::Response->new();
  my $answer;
  $res->{status} = 0;
  for(my $retry = 0; $retry <= 9; $retry++){
    $http_res = $ua->request(new HTTP::Request('GET', $aws_url));
    if($http_res->is_error) {
      if ($http_res->code == 503 || $http_res->code == 500) {
        if($retry < 9){
          redo;
        }
      }
      push(@{$res->{messages}}, "Error Raised");
      return $res;
    }
    else{
      if($http_res->{'_content'} =~ /Internal Error/){
        if($retry < 9){
          redo;
        }
        push(@{$res->{messages}}, "Error Raised");
        return $res;
      }
      $res->{rawdata} = $http_res->{'_content'};
      
      $answer = XMLin($res->{rawdata});
      last;
    }
  }

  if(!($answer)){
    push(@{$res->{messages}}, "Error Raised");
    return $res;
  }
    
  if($answer->{Items}->{TotalResults}){
    $res->{total_results} = $answer->{Items}->{TotalResults};
  }
  if($answer->{Items}->{TotalPages}){
    $res->{total_pages}   = $answer->{Items}->{TotalPages};
  }
  
  if (ref($answer->{Items}->{Item}) eq 'ARRAY') {
    foreach my $thisItem(@{$answer->{Items}->{Item}}){
      $res->push_item($thisItem);
    }
    $res->{status} = 1;
  }
  elsif($answer->{Items}->{Item}){
    $res->push_item($answer->{Items}->{Item});
    $res->{status} = 1;
  }
  else{
    if($answer->{Items}->{Request}->{Errors}->{Error}){
      my $ptrError = $answer->{Items}->{Request}->{Errors}->{Error};
      if (ref($ptrError) eq 'ARRAY') {
        foreach my $thisError(@{$ptrError}){
          push(@{$res->{messages}}, $thisError->{Message});
        }
      }
      else{
        push(@{$res->{messages}}, $ptrError->{Message});
      }
    }
  }
  return $res;
}

####------------------------------------------------------------------------
#### Asinコードによる検索を行う
####------------------------------------------------------------------------
sub itemLookup {
  # パラメータの取得
  my ($self, $param, $expires_in) = @_;
  if(!defined($expires_in) || $expires_in eq ''){
    $expires_in = "60 minutes";
  }

  # リクエストの生成
  my   @query;
  push @query, "Operation=ItemLookup";
  push @query, "ItemId=$param";
  push @query, "MerchantId=Amazon";
  push @query, "Conditon=New";
  push @query, "ResponseGroup=Medium,Tracks,Accessories,SalesRank,EditorialReview,Images,Reviews,ItemAttributes";
  push @query, "ItemPage=1";
  
  # File::Cache
  my $cacheKey = "ASIN_${param}";
  eval {require Cache::FileCache};
  unless ($@) {
    require Cache::FileCache;
    import  Cache::FileCache;

    my $cache = new Cache::FileCache();
    $cache->purge();
    my $res = $cache->get($cacheKey);
    unless(defined($res)){
      $res = $self->request($cacheKey, @query);
      $cache->set($cacheKey, $res, $expires_in);
    }
    return $res;
  }

  return $self->request($cacheKey, @query);
}

1;
