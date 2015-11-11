#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IPC::Open3 'open3';
use Symbol 'gensym';
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

for my $host (@hosts) {
    my ($stdin, $stdout, $stderr) = (undef, undef, gensym);

    my $pid = open3($stdin, $stdout, $stderr, 'ssh', '-T', '-o', 'BatchMode=yes',
                    $host, 'sh');
    print $stdin $script;
    close $stdin;

    my @stdout = <$stdout>;
    my @stderr = <$stderr>;
    close $stdout;
    close $stderr;

    waitpid($pid, 0);

    print color('yellow bold'), sprintf "host: %-20s\n" => $host;
    print color('reset'), color('green'), @stdout;
    print color('reset'), color('red'),   @stderr;
    print color('reset'), "\n";
}

exit;
