#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use AnyEvent::Open3::Simple;
use Term::ANSIColor;

## poor man's slurp
my $script = do {
    my $file = shift @ARGV or die "usage: $0 script hosts\n";
    local $/;
    open my $fh, "<", $file or die "Unable to open '$file': $!\n";
    <$fh>
};

my @hosts = <>;
chomp @hosts;

my %hostname = my %status = my %stdout = my %stderr = ();

my $cv = AnyEvent->condvar;
$cv->begin(sub { shift->send });  ## this triggers when $cv counter reaches 0

for my $host (@hosts) {
    $cv->begin;  ## increment $cv counter

    my $conn = AnyEvent::Open3::Simple->new(
        on_start => sub {
            my $pid = shift->pid;
            $hostname{$host} = $pid;
            $status{$pid}    = 'running';
            $stdout{$pid}    = [];
            $stderr{$pid}    = [];
        },

        on_stdout => sub { push @{ $stdout{ shift->pid } }, @_ },
        on_stderr => sub { push @{ $stderr{ shift->pid } }, @_ },

        ## $cv->end decrements $cv counter
        on_error   => sub { $status{ shift->pid } = 'error';   $cv->end },
        on_success => sub { $status{ shift->pid } = 'success'; $cv->end },
        on_fail    => sub { $status{ shift->pid } = 'failed';  $cv->end },
    );

    $conn->run('ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=no', '-o', 'ConnectTimeout=2',
        $host, 'sh', \$script);
}

$cv->end;
$cv->recv;    ## return to the event loop until $cv->send()

for my $host (sort keys %hostname) {
    my $pid = $hostname{$host};
    print color('yellow bold'), sprintf "host: %-20s [%-5d]: %s\n" => $host, $pid, $status{$pid};
    print color('reset'), color('green'), join "\n" => @{ $stdout{$pid} }, '';
    print color('reset'), color('red'),   join "\n" => @{ $stderr{$pid} }, '';
    print color('reset'), "\n";
}
