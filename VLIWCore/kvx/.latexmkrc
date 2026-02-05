#!/usr/bin/env perl
# From https://tex.stackexchange.com/a/474915

$ENV{'TEXINPUTS'} .= ':$KALRAY_REQ_DIR/kalray_internal/share/kalray-latex//:';

add_cus_dep('glo', 'gls', 0, 'makeglo2gls');
sub makeglo2gls {
   system("makeindex -s '$_[0]'.ist -t '$_[0]'.glg -o '$_[0]'.gls '$_[0]'.glo");
}
