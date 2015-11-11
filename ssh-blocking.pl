#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IPC::Open3 'open3';
use Symbol 'gensym';

my $host = shift @ARGV or die "usage: $0 <hostname>\n";

my ($stdin, $stdout, $stderr) = (undef, undef, gensym);

my $script = <<_SCRIPT_;
date
uptime
ls -l no-such-file
sleep 2
_SCRIPT_

my $pid = open3($stdin, $stdout, $stderr, 'ssh', '-T', '-o', 'BatchMode=yes',
                $host, 'sh');
print $stdin $script;
close $stdin;

my @stdout = <$stdout>;
my @stderr = <$stderr>;
close $stdout;
close $stderr;

waitpid($pid, 0);

say "STDOUT:\n@stdout";
say "STDERR:\n@stderr";

exit;
