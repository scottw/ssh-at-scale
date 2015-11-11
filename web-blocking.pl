#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use Mojo::UserAgent;


my $file = shift @ARGV
  or die "usage: $0 <urls.txt>\n";

open my $fh, "<", $file;

my $ua = Mojo::UserAgent->new;



while (my $url = <$fh>) {

    chomp $url;
    next unless $url =~ /^http/;

    my $tx = $ua->get($url);
    my $title = eval { $tx->res->dom->at('title')->text };
    $title //= '(untitled)';
    say "($url): $title";


}



close $fh;
