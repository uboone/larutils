#!/bin/bash

# build uboonecode and ubutil 
# use mrb
# designed to work on Jenkins
# this is a proof of concept script

echo "uboonecode version: $UBOONE"
echo "ubuitil version: $UBUTIL"
echo "base qualifiers: $QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`


#source /grid/fermiapp/products/larsoft/setup || exit 1
source /grid/fermiapp/products/uboone/setup_uboone.sh || exit 1

setup git || exit 1
setup gitflow || exit 1
setup mrb || exit 1
export MRB_PROJECT=uboone

set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
mrb newDev  -v $UBOONE -q $QUAL:$BUILDTYPE || exit 1
set +x

source localProducts*/setup || exit 1

# some shenanigans so we can use mrb v1_04_01
cd $MRB_INSTALL
curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/packages/mrb/v1_04_01/mrb-1.04.01-noarch.tar.bz2  || \
      { cat 1>&2 <<EOF
ERROR: pull of http://scisoft.fnal.gov/scisoft/packages/mrb/v1_04_01/mrb-1.04.01-noarch.tar.bz2 failed
EOF
        exit 1
      }
tar xf mrb-1.04.01-noarch.tar.bz2 || exit 1
setup mrb  || exit 1
which mrb

set -x
cd $MRB_SOURCE  || exit 1
# make sure we get a read-only copy
mrb g -r -t $UBOONE uboonecode || exit 1
mrb g -r -t $UBUTIL ubutil || exit 1
cd $MRB_BUILDDIR || exit 1
mrbsetenv || exit 1
mrb b -j$ncores || exit 1
mrb mp -n uboone -- -j$ncores || exit 1
# add uboone_data to the manifest
uboone_data_version=`grep uboone_data $MRB_SOURCE/uboonecode/ups/product_deps  | grep -v qualifier | sed -e 's/[ \t]\{1,\}/ /g' | cut -f2 -d" "`
uboone_data_dot_version=`echo ${uboone_data_version} |  sed -e 's/_/./g' | sed -e 's/^v//'`
echo "uboone_data        ${uboone_data_version}       uboone_data-${uboone_data_dot_version}-noarch.tar.gz" >>  uboone-*_MANIFEST.txt
mv *.bz2  $WORKSPACE/copyBack/ || exit 1
mv uboone*.txt  $WORKSPACE/copyBack/ || exit 1
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1
set +x

exit 0
