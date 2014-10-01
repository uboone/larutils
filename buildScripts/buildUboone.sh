#!/bin/bash

# build uboonecode and ubutil 
# use mrb
# designed to work on Jenkins
# this is a proof of concept script

echo "larsoft version: $LARVER"
echo "uboonecode version: $UBOONE"
echo "ubuitil version: $UBUTIL"
echo "base qualifiers: $QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`

set -x

source /grid/fermiapp/products/larsoft/setup || exit 1
setup git || exit 1
setup gitflow || exit 1
setup mrb || exit 1
export MRB_PROJECT=uboone

mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
cd $WORKSPACE/temp || exit 1
mrb newDev  -v $UBOONE -q $QUAL:$BUILDTYPE || exit 1
source localProducts*/setup || exit 1
cd $MRB_SOURCE  || exit 1
mrb g -t $UBOONE uboonecode || exit 1
mrb g -t $UBUTIL ubutil || exit 1
cd $MRB_BUILDDIR || exit 1
mrb b -j$ncores || exit 1
mrb mp -j$ncores || exit 1
mv *.bz2  $WORKSPACE/copyBack/ || exit 1
cd $WORKSPACE || exit 1
rm -rf temp || exit 1

exit 0
