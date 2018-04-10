#!/bin/bash

#------------------------------------------------------------------
#
# Name: build_larlite.sh
#
# Purpose: Build debug and prof flavors of larlite on Jenkins.
#
# Created:  4-Aug-2017  H. Greenlee
#
#------------------------------------------------------------------

echo "larlite ups version: $UPS_VERSION"
echo "larlite git tag: $GIT_TAG"
echo "qualifier: $QUAL"
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
export LARLITE_HOME_DIR=`pwd`

set +x

# Make source area and check out sources.

mkdir -p srcs
cd srcs
#git clone https://github.com/larlight/larlite
git clone https://github.com/hgreenlee/larlite
cd larlite
git checkout $GIT_TAG
rm -rf .git

# Set up the correct version of gcc.

if [[ $QUAL =~ ^c ]]; then
  compiler_version=`ups depend -M ups -m larlite.table -q ${QUAL}:${BUILDTYPE} larlite | sed -n 's/^.*__\(clang .*\)$/\1/p'`
else
  compiler_version=`ups depend -M ups -m larlite.table -q ${QUAL}:${BUILDTYPE} larlite | sed -n 's/^.*__\(gcc .*\)$/\1/p'`
fi
setup $compiler_version

# Set up the correct dependent root version.

root_version=`ups depend -M ups -m larlite.table -q ${QUAL}:${BUILDTYPE} larlite | sed -n 's/^.*__\(root .*\)$/\1/p'`
setup $root_version

# Do post-checkout initialization.

source config/setup.sh || exit 1
if [[ $QUAL =~ ^c ]]; then
  export LARLITE_CXX=clang++
else
  export LARLITE_CXX=g++
fi

# Run make

make -j$ncores || exit 1

# Assemble ups product.

install_dir=${LARLITE_HOME_DIR}/install/larlite/$UPS_VERSION
subdir=`get-directory-name subdir ${QUAL}:${BUILDTYPE}`
flavor_dir=${install_dir}/$subdir
mkdir -p $flavor_dir
cp -r . $flavor_dir
cp -r ups $install_dir

# Make a dbconfig file.

mkdir ${LARLITE_HOME_DIR}/install/.upsfiles
cat <<EOF > ${LARLITE_HOME_DIR}/install/.upsfiles/dbconfig
FILE = DBCONFIG
AUTHORIZED_NODES = *
VERSION_SUBDIR = 1
PROD_DIR_PREFIX = \${UPS_THIS_DB}
UPD_USERCODE_DIR = \${UPS_THIS_DB}/.updfiles
EOF

# Declare ups product in temporary products area.

if uname | grep -q Darwin; then
  flavor=`ups flavor -2`
else
  flavor=`ups flavor -4`
fi
ups declare -z ${LARLITE_HOME_DIR}/install -r larlite/$UPS_VERSION -m larlite.table -f $flavor -q ${QUAL}:${BUILDTYPE} -U ups larlite $UPS_VERSION

# Make distribution tarball

cd ${LARLITE_HOME_DIR}/install
dot_version=`echo $UPS_VERSION | sed -e 's/_/\./g' | sed -e 's/^v//'`
subdir=`echo $subdir | sed -e 's/\./-/g'`
#qual=`echo $CETPKG_QUAL | sed -e 's/:/-/g'`
tarballname=larlite-${dot_version}-${subdir}.tar.bz2
echo "Making ${tarballname}"
tar cjf ${LARLITE_HOME_DIR}/${tarballname} larlite

# Save artifacts.

mv ${LARLITE_HOME_DIR}/${tarballname}  $WORKSPACE/copyBack/ || exit 1
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
#rm -rf $WORKSPACE/temp || exit 1
set +x

exit 0
