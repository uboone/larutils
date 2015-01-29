#!/bin/bash

# build lbnecode 
# use mrb
# designed to work on Jenkins
# this is a proof of concept script

echo "lbneutil version: $LBNEUTILVER"
echo "base qualifiers: $QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`


source /grid/fermiapp/products/larsoft/setup || exit 1

setup git || exit 1
setup gitflow || exit 1
setup mrb || exit 1
export MRB_PROJECT=lbne
which mrb

set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
mrb newDev  -v $LBNEVER -q $QUAL:$BUILDTYPE || exit 1
set +x

source localProducts*/setup || exit 1

set -x
cd $MRB_SOURCE  || exit 1
# make sure we get a read-only copy
mrb g -r -t $LBNEVER lbneutil || exit 1
cd $MRB_BUILDDIR || exit 1
mrbsetenv || exit 1
mrb b -j$ncores || exit 1
mrb mp -j$ncores || exit 1
mv *.bz2  $WORKSPACE/copyBack/ || exit 1
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1
set +x

exit 0
