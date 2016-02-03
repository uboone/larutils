#!/bin/bash

# build lariatsoft, lariatutil and lbne_raw_data
# use mrb
# designed to work on Jenkins
# this is a proof of concept script

echo "lariatsoft version: $LARIAT"
echo "base qualifiers: $QUAL"
echo "larsoft qualifiers: $LARSOFT_QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

# Don't do ifdh build on macos.

#if uname | grep -q Darwin; then
#  if ! echo $QUAL | grep -q noifdh; then
#    echo "Ifdh build requested on macos.  Quitting."
#    exit
#  fi
#fi

# Get number of cores to use.

if [ `uname` = Darwin ]; then
  #ncores=`sysctl -n hw.ncpu`
  #ncores=$(( $ncores / 4 ))
  ncores=16
else
  ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`
fi
if [ $ncores -lt 1 ]; then
  ncores=1
fi
echo "Building using $ncores cores."

# Environment setup, uses /grid/fermiapp or cvmfs.

#echo "ls /cvmfs/lariat.opensciencegrid.org/products/lariat/"
#ls /cvmfs/lariat.opensciencegrid.org/products/lariat/
#echo

if [ -f /grid/fermiapp/lariat/setup_lariat.sh ]; then
  source /grid/fermiapp/lariat/setup_lariat.sh || exit 1
else
  echo "No setup file found."
  exit 1
fi

# Use system git on macos.

if ! uname | grep -q Darwin; then
  setup git || exit 1
fi
setup gitflow || exit 1
export MRB_PROJECT=lariat
echo "Mrb path:"
which mrb

set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
mrb newDev -v $LARIAT -q $QUAL:$BUILDTYPE || exit 1

set +x
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

set -x
cd $MRB_SOURCE  || exit 1
# make sure we get a read-only copy
mrb g -r -t $LARIAT lariatsoft || exit 1

# Extract lariatutil version from lariatsoft product_deps
lariatutil_version=`grep lariatutil $MRB_SOURCE/lariatsoft/ups/product_deps | grep -v qualifier | awk '{print $2}'`
echo "lariatuitil version: $lariatutil_version"
mrb g -d lariatutil -t $lariatutil_version http://cdcvs.fnal.gov/projects/lardbt-lariatutil/ || exit 1

# Extract lariatfragments version from lariatsoft product_deps
lariatfragments_version=`grep lariatfragments $MRB_SOURCE/lariatsoft/ups/product_deps | grep -v qualifier | awk '{print $2}'`
echo "ubuitil version: $lariatfragments_version"
mrb g -d lariatfragments -t $lariatfragments_version http://cdcvs.fnal.gov/projects/lariat-online-lariatfragments/ || exit 1

cd $MRB_BUILDDIR || exit 1
mrbsetenv || exit 1
mrb b -j$ncores || exit 1
mrb mp -n lariat -- -j$ncores || exit 1

manifest=lariat-*_MANIFEST.txt

if echo $QUAL | grep -q nobeam; then
    echo $QUAL
else
# add LariatBeamFiles to the manifest
# currently does not exist on scisoft
    LariatBeamFiles_version=`grep LariatBeamFiles $MRB_SOURCE/lariatsoft/ups/product_deps | grep -v qualifier | awk '{print $2}'`
    LariatBeamFiles_dot_version=`echo ${LariatBeamFiles_version} | sed -e 's/_/./g' | sed -e 's/^v//'`
#    echo "LariatBeamFiles      ${LariatBeamFiles_version}          LariatBeamFiles-${LariatBeamFiles_dot_version}-noarch.tar.bz2" >>  $manifest
fi    

LariatFilters_version=`grep LariatFilters $MRB_SOURCE/lariatsoft/ups/product_deps | grep -v qualifier | awk '{print $2}'`
LariatFilters_dot_version=`echo ${LariatFilters_version} | sed -e 's/_/./g' | sed -e 's/^v//'`
echo "LariatFilters        ${LariatFilters_version}          LariatFilters-${LariatFilters_dot_version}-noarch.tar.gz" >>  $manifest

# Extract larsoft version from product_deps.

larsoft_version=`grep larsoft $MRB_SOURCE/lariatsoft/ups/product_deps | grep -v qualifier | awk '{print $2}'`
larsoft_dot_version=`echo ${larsoft_version} |  sed -e 's/_/./g' | sed -e 's/^v//'`

# Extract flavor.

flvr=''
if uname | grep -q Darwin; then
  flvr=`ups flavor -2`
else
  flvr=`ups flavor`
fi

# Construct name of larsoft manifest.

larsoft_hyphen_qual=`echo $LARSOFT_QUAL | tr : - | sed 's/-noifdh//'`
larsoft_manifest=larsoft-${larsoft_dot_version}-${flvr}-${larsoft_hyphen_qual}-${BUILDTYPE}_MANIFEST.txt
echo "Larsoft manifest:"
echo $larsoft_manifest
echo

# Fetch laraoft manifest from scisoft and append to lariatsoft manifest.

curl --fail --silent --location --insecure http://scisoft.fnal.gov/scisoft/bundles/larsoft/${larsoft_version}/manifest/${larsoft_manifest} >> $manifest || exit 1

# Special handling of noifdh builds goes here.

if echo $QUAL | grep -q noifdh; then

  if uname | grep -q Darwin; then

    # If this is a macos build, then rename the manifest to remove noifdh qualifier in the name

    noifdh_manifest=`echo $manifest | sed 's/-noifdh//'`
    mv $manifest $noifdh_manifest

  else

    # Otherwise (for slf builds), delete the manifest entirely.

    rm -f $manifest

  fi
fi

# Save artifacts.

mv *.bz2  $WORKSPACE/copyBack/ || exit 1
manifest=lariat-*_MANIFEST.txt
if [ -f $manifest ]; then
  mv $manifest  $WORKSPACE/copyBack/ || exit 1
fi
#cp $MRB_BUILDDIR/lariatsoft/releaseDB/*.html $WORKSPACE/copyBack/
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1
set +x

exit 0
