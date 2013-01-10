#!/bin/sh

. ../../configure.inc

savedir=`pwd`
cd ../..
./configure.sh
cd $savedir

sed -e "/@include@/s||$INCLUDE|" \
    -e "/@q@/s||$Q|g" \
    -e "/@INSTALL@/s||$INSTALL|" \
    -e "/@TCLSH@/s||$TCLSH|" Makefile.in > Makefile
