#!/bin/bash

# build uboonecode and uboone suite packages.
# uses buildFW
# designed to work on Jenkins

# Extract set qualifier from $LARSOFT_QUAL (we don't care about anything else in $LARSOFT_QUAL).

SQUAL=`echo $LARSOFT_QUAL | tr : '\n' | grep ^s`

echo "uboonecode version: $VERSION"
echo "base qualifiers: $QUAL"
echo "set qualifier: $SQUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

# Get number of cores to use.

if [ `uname` = Darwin ]; then
  #ncores=`sysctl -n hw.ncpu`
  #ncores=$(( $ncores / 4 ))
  ncores=1
else
  ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`
fi
if [ $ncores -lt 1 ]; then
  ncores=1
fi
echo "Building using $ncores cores."

# Environment setup, uses /grid/fermiapp or cvmfs.
# For now, use bluearc setup for macos, cvmfs for linux.

if [ `uname` = Darwin -a -f /grid/fermiapp/products/uboone/setup_uboone_bluearc.sh ]; then
  source /grid/fermiapp/products/uboone/setup_uboone_bluearc.sh || exit 1
elif [ -f /cvmfs/uboone.opensciencegrid.org/products/setup_uboone.sh ]; then
  source /cvmfs/uboone.opensciencegrid.org/products/setup_uboone.sh || exit 1
else
  echo "No setup file found."
  exit 1
fi

# Use system git on macos.

if ! uname | grep -q Darwin; then
  setup git || exit 1
fi
setup gitflow || exit 1

# use getopt v1_1_6 on macos (not sure if this is needed).
if [ `uname` = Darwin ]; then
  setup getopt v1_1_6  || exit 1
fi

# Create area for biuld artifacts.
rm -f $WORKSPACE/copyBack
mkdir -p $WORKSPACE/copyBack || exit 1

# Create build directory and go there.
blddir=${WORKSPACE}/build
rm -rf $blddir
mkdir -p $blddir || exit 1
cd $blddir || exit 1

# Fetch buildFW script.
echo "Fetching buildFW."
curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/bundles/tools/buildFW || exit 1
chmod +x buildFW

# Do build.
echo
echo "Begin build."
echo
./buildFW -t -b $QUAL -s $SQUAL $blddir $BUILDTYPE uboone-$VERSION || \
 { mv ${blddir}/*.log $WORKSPACE/copyBack
   exit 1
 }

# Save artifacts.

mv *.bz2  $WORKSPACE/copyBack/ || exit 1
mv *.txt $WORKSPACE/copyBack/ || exit 1
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $blddir || exit 1

exit 0
