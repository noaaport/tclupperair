#!/bin/sh
#
# $Id: export.sh,v f54f2b62373a 2009/09/11 16:26:33 nieves $
#

tmpdir=tmp

# read name and version
. ../VERSION

rm -r -f $tmpdir
mkdir $tmpdir

cd $tmpdir
cvs -d :ext:nieves@${name}.cvs.sourceforge.net:/cvsroot/${name} \
    export -D now -d ${name}-${version} ${name}

tar -czf ../${name}-${version}.tgz ${name}-${version}

cd ..
rm -r $tmpdir
