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
