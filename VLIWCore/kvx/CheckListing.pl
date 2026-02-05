#!/usr/bin/perl -w
#
$/ = "";
print ".text\n";
while(<>) {
  if (/^\\begin{lstlisting}/) {
    my @lines = map { s/\.\.\./or \$r0=\$r0,\$r0/; $_ } split /\n/;
    my $text = join "\n", grep { !/lstlisting/ } @lines;
    print $text, "\n;;\n";
  }
}

0;

