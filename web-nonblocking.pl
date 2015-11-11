#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use Mojo::UserAgent;
use Mojo::IOLoop;

my $file = shift @ARGV
  or die "usage: $0 <urls.txt>\n";

open my $fh, "<", $file;

my $ua = Mojo::UserAgent->new;

my $delay = Mojo::IOLoop::Delay->new;

while (my $url = <$fh>) {
    my $end = $delay->begin;
    chomp $url;
    next unless $url =~ /^http/;

    $ua->get($url, sub {
        my $title = eval { pop->res->dom->at('title')->text };
        $title //= '(untitled)';
        say "($url): $title";
        $end->();
    });
}

$delay->wait;

close $fh;
