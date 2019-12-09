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

# Create area for biuld artifacts.
rm -rf $WORKSPACE/copyBack
mkdir -p $WORKSPACE/copyBack || exit 1

# Check for supported combination of base qualifier and OS.
if [[ `uname -s` == Darwin ]] && [[ $QUAL == e* ]]; then
  echo "${QUAL} build not supported on `uname -s`"
  echo "${QUAL} build not supported on `uname -s`" > $WORKSPACE/copyBack/skipping_build
  exit 0
fi

# Create build directory and go there.
blddir=${WORKSPACE}/build
logdir=${WORKSPACE}/log
rm -rf $blddir
rm -rf $logdir
mkdir -p $blddir || exit 1
mkdir -p $logdir || exit 1
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
 { mv *.log $logdir
   exit 1
 }

# Save log files.

mv *.log $logdir || exit 1

# Save artifacts.

mv ub*.bz2  $WORKSPACE/copyBack/ || exit 1
mv larlite*.bz2  $WORKSPACE/copyBack/ || exit 1
mv larcv*.bz2  $WORKSPACE/copyBack/ || exit 1
mv swtrigger*.bz2  $WORKSPACE/copyBack/ || exit 1
mv *.txt $WORKSPACE/copyBack/ || exit 1
mv wcp*.bz2  $WORKSPACE/copyBack/ || echo "No wcp tarball"
mv glpk*.bz2  $WORKSPACE/copyBack/ || echo "No wcp tarball"

# Clean up.

cd $WORKSPACE || exit 1
rm -rf $blddir || exit 1

exit 0
