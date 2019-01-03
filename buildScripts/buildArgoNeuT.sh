#!/bin/bash

# build argoneutcode 
# use mrb
# designed to work on Jenkins
# this is a proof of concept script
df
ls /cvmfs/argoneut.opensciencegrid.org

echo "argoneutcode version: $ARGONEUTVER"
echo "base qualifiers: $QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

if [ `uname` = Darwin ]; then
  #ncores=`sysctl -n hw.ncpu`
  #ncores=$(( $ncores / 4 ))
  ncores=4
else
  ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`
fi
if [ $ncores -lt 1 ]; then
  ncores=1
fi
echo "Building using $ncores cores."

#source /grid/fermiapp/products/argoneut/setup_argoneut_fermiapp.sh || exit 1
#source /grid/fermiapp/products/argoneut/setup_argoneut.sh || exit 1

if [ `uname` = Darwin -a -f /grid/fermiapp/products/argoneut/setup_argoneut_fermiapp.sh ]; then
  source /grid/fermiapp/products/argoneut/setup_argoneut_fermiapp.sh || exit 1
elif [ -f /cvmfs/argoneut.opensciencegrid.org/products/argoneut/setup_argoneut.sh ]; then
  source /cvmfs/argoneut.opensciencegrid.org/products/argoneut/setup_argoneut.sh || exit 1
else
  echo "No setup file found."
  exit 1
fi


# skip around a version of mrb that does not work on macOS

if [ `uname` = Darwin ]; then
  if [[ x`which mrb | grep v1_17_02` != x ]]; then
    unsetup mrb || exit 1
    setup mrb v1_16_02 || exit 1
  fi
fi


if ! uname | grep -q Darwin; then
  setup git || exit 1
fi
setup gitflow || exit 1
export MRB_PROJECT=argoneut
echo "Mrb path:"
which mrb

#set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
mrb newDev  -v $ARGONEUTVER -q $QUAL:$BUILDTYPE || exit 1
#set +x

source localProducts*/setup || exit 1

# some shenanigans so we can use getopt v1_1_6
if [ `uname` = Darwin ]; then
#  cd $MRB_INSTALL
#  curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/packages/getopt/v1_1_6/getopt-1.1.6-d13-x86_64.tar.bz2 || \
#      { cat 1>&2 <<EOF
#ERROR: pull of http://scisoft.fnal.gov/scisoft/packages/getopt/v1_1_6/getopt-1.1.6-d13-x86_64.tar.bz2 failed
#EOF
#        exit 1
#      }
#  tar xf getopt-1.1.6-d13-x86_64.tar.bz2 || exit 1
  setup getopt v1_1_6  || exit 1
#  which getopt
fi

#set -x
cd $MRB_SOURCE  || exit 1
# make sure we get a read-only copy
mrb g -r -t $ARGONEUTVER argoneutcode || exit 1
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
