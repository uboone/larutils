#!/bin/bash

#------------------------------------------------------------------
#
# Name: build_uboonedaq_datatypes.sh
#
# Purpose: Build debug and prof flavors of uboonedaq_datatypes
#          on Jenkins.
#
# Created:  25-Jun-2015  H. Greenlee
#
#------------------------------------------------------------------

echo "uboonedaq_datatypes version: $VERSION"
echo "Qualifier: $QUAL"
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

# Interpret build type.

opt=''
if [ $BUILDTYPE = debug ]; then
  opt='-d'
elif [ $BUILDTYPE = prof ]; then
  opt='-p'
else
  echo "Unknown build type $BUILDTYPE"
  exit 1
fi

# Environment setup, uses /grid/fermiapp or cvmfs.

if [ -f /grid/fermiapp/products/uboone/setup_uboone.sh ]; then
  source /grid/fermiapp/products/uboone/setup_uboone.sh || exit 1
elif [ -f /cvmfs/uboone.opensciencegrid.org/products/setup_uboone.sh ]; then
  if [ -x /cvmfs/grid.cern.ch/util/cvmfs-uptodate ]; then
    /cvmfs/grid.cern.ch/util/cvmfs-uptodate /cvmfs/uboone.opensciencegrid.org/products
  fi
  source /cvmfs/uboone.opensciencegrid.org/products/setup_uboone.sh || exit 1
else
  echo "No setup file found."
  exit 1
fi

# Use system git on macos.

if ! uname | grep -q Darwin; then
  setup git || exit 1
fi

# Set up working area.

set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
export UBOONEDAQ_HOME_DIR=`pwd`

set +x

# Make build area.

mkdir -p build

# Make install area.

mkdir -p install

# Make source area and check out sources.

mkdir -p srcs
cd srcs
git clone http://cdcvs.fnal.gov/projects/uboonedaq-datatypes
#git clone https://github.com/hgreenlee/uboonedaq_datatypes
#mv uboonedaq_datatypes uboonedaq-datatypes
cd uboonedaq-datatypes

# Make sure repository is up to date and check out desired tag.

git checkout master
git pull
git checkout $VERSION

# Initialize build area.

cd ${UBOONEDAQ_HOME_DIR}/build
source ${UBOONEDAQ_HOME_DIR}/srcs/uboonedaq-datatypes/projects/ups/setup_for_development $opt $QUAL

# Run cmake.

env CC=gcc CXX=g++ FC=gfortran cmake -DCMAKE_INSTALL_PREFIX="${UBOONEDAQ_HOME_DIR}/install" -DCMAKE_BUILD_TYPE=${CETPKG_TYPE} "${CETPKG_SOURCE}"

# Run make

make -j$ncores
make install

# Make distribution tarball

cd ${UBOONEDAQ_HOME_DIR}/install
dot_version=`echo $VERSION | sed -e 's/_/\./g' | sed -e 's/^v//'`
subdir=`echo $CET_SUBDIR | sed -e 's/\./-/g'`
qual=`echo $CETPKG_QUAL | sed -e 's/:/-/g'`
tarballname=uboonedaq_datatypes-${dot_version}-${subdir}-${qual}.tar.bz2
echo "Making ${tarballname}"
tar cjf ${UBOONEDAQ_HOME_DIR}/${tarballname} uboonedaq_datatypes

# Save artifacts.

mv ${UBOONEDAQ_HOME_DIR}/${tarballname}  $WORKSPACE/copyBack/ || exit 1
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1
set +x

exit 0
