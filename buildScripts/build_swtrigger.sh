#!/bin/bash

#------------------------------------------------------------------
#
# Name: build_swtrigger.sh
#
# Purpose: Build debug and prof flavors of swtrigger on Jenkins.
#
# Created:  25-Jun-2015  H. Greenlee
#
#------------------------------------------------------------------

echo "swtrigger version: $VERSION"
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

# Other required setups.

setup cetbuildtools v5_04_02

# Set up working area.

set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
export SWTRIGGER_HOME_DIR=`pwd`

set +x

# Make source area and check out sources.

mkdir -p srcs
cd srcs
#git clone https://github.com/twongjirad/fememulator
git clone https://github.com/hgreenlee/fememulator
cd fememulator

# Make sure repository is up to date and check out desired tag.

git checkout master
git pull
git checkout $VERSION

# Set up the correct version of compiler ups product.

if [[ $QUAL =~ ^c ]]; then
  compiler_version=`ups depend -M ${SWTRIGGER_HOME_DIR}/srcs/fememulator/ups -m swtrigger.table -q ${QUAL}:${BUILDTYPE} swtrigger | sed -n 's/^.*__\(clang .*\)$/\1/p'`
else
  compiler_version=`ups depend -M ${SWTRIGGER_HOME_DIR}/srcs/fememulator/ups -m swtrigger.table -q ${QUAL}:${BUILDTYPE} swtrigger | sed -n 's/^.*__\(gcc .*\)$/\1/p'`
fi
setup $compiler_version

# Do post-checkout initialization.

source configure.sh

# Run cmake.

mkdir build 
cd build
if [[ $QUAL =~ ^c ]]; then
  cmake .. -DCMAKE_CXX_COMPILER=`which clang++` -DCMAKE_BUILD_TYPE=$BUILDTYPE || exit 1
else
  cmake .. -DCMAKE_CXX_COMPILER=`which g++` -DCMAKE_BUILD_TYPE=$BUILDTYPE || exit 1
fi

# Run make

make -j$ncores || exit 1

# Assemble ups product.

install_dir=${SWTRIGGER_HOME_DIR}/install/swtrigger/$VERSION
subdir=`get-directory-name subdir ${QUAL}:${BUILDTYPE}`
binary_dir=${install_dir}/$subdir
src_dir=${install_dir}/source
mkdir -p $binary_dir
mkdir -p $src_dir
cp -r lib $binary_dir
cp -r ${SWTRIGGER_HOME_DIR}/srcs/fememulator/SWTriggerBase $src_dir
cp -r ${SWTRIGGER_HOME_DIR}/srcs/fememulator/FEMBeamTrigger $src_dir
cp -r ${SWTRIGGER_HOME_DIR}/srcs/fememulator/ups $install_dir
mkdir ${SWTRIGGER_HOME_DIR}/install/.upsfiles

# Make a dbconfig file.

cat <<EOF > ${SWTRIGGER_HOME_DIR}/install/.upsfiles/dbconfig
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
ups declare -z ${SWTRIGGER_HOME_DIR}/install -r swtrigger/$VERSION -m swtrigger.table -f $flavor -q ${QUAL}:${BUILDTYPE} -U ups swtrigger $VERSION

# Make distribution tarball

cd ${SWTRIGGER_HOME_DIR}/install
dot_version=`echo $VERSION | sed -e 's/_/\./g' | sed -e 's/^v//'`
subdir=`echo $subdir | sed -e 's/\./-/g'`
#qual=`echo $CETPKG_QUAL | sed -e 's/:/-/g'`
tarballname=swtrigger-${dot_version}-${subdir}.tar.bz2
echo "Making ${tarballname}"
tar cjf ${SWTRIGGER_HOME_DIR}/${tarballname} swtrigger

# Save artifacts.

mv ${SWTRIGGER_HOME_DIR}/${tarballname}  $WORKSPACE/copyBack/ || exit 1
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
#rm -rf $WORKSPACE/temp || exit 1
set +x

exit 0
