#!/bin/bash

#------------------------------------------------------------------
#
# Name: build_larcv.sh
#
# Purpose: Build debug and prof flavors of larcv and larlite on Jenkins.
#
# Created:  4-Aug-2017  H. Greenlee
#
#------------------------------------------------------------------

echo "larcv ups version: $LARCV_VERSION"
echo "larcv git tag: $LARCV_TAG"
echo "larlite ups version: $LARLITE_VERSION"
echo "larlite git tag: $LARLITE_TAG"
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
export HOME_DIR=`pwd`

set +x

# Make an installation directory with relocatable dbconfig file.

mkdir -p ${HOME_DIR}/install/.upsfiles
cat <<EOF > ${HOME_DIR}/install/.upsfiles/dbconfig
FILE = DBCONFIG
AUTHORIZED_NODES = *
VERSION_SUBDIR = 1
PROD_DIR_PREFIX = \${UPS_THIS_DB}
UPD_USERCODE_DIR = \${UPS_THIS_DB}/.updfiles
EOF

# Make source area and check out sources.

mkdir -p ${HOME_DIR}/srcs
cd ${HOME_DIR}/srcs

# Check out larcv.

#git clone https://github.com/LArbys/LArCV
git clone https://github.com/hgreenlee/LArCV
cd LArCV
git checkout $LARCV_TAG
rm -rf .git
cd ..

# Check out larlite.

git clone https://github.com/larlight/larlite
#git clone https://github.com/hgreenlee/larlite
cd larlite
git checkout $LARLITE_TAG
rm -rf .git
cd ..

# Set up the correct version of gcc.

gcc_version=`ups depend -M ${HOME_DIR}/srcs/LArCV/ups -m larcv.table -q ${QUAL}:${BUILDTYPE} larcv | sed -n 's/^.*__\(gcc .*\)$/\1/p'`
gcc_version2=`ups depend -M ${HOME_DIR}/srcs/larlite/ups -m larlite.table -q ${QUAL}:${BUILDTYPE} larlite | sed -n 's/^.*__\(gcc .*\)$/\1/p'`
if [ "$gcc_version" != "$gcc_version2" ]; then
  echo "Gcc versions do not match."
  echo $gcc_version
  echo $gcc_version2
  exit 1
fi
setup $gcc_version

# Set up the correct version of root.

root_version=`ups depend -M ${HOME_DIR}/srcs/LArCV/ups -m larcv.table -q ${QUAL}:${BUILDTYPE} larcv | sed -n 's/^.*__\(root .*\)$/\1/p'`
root_version2=`ups depend -M ${HOME_DIR}/srcs/larlite/ups -m larlite.table -q ${QUAL}:${BUILDTYPE} larlite | sed -n 's/^.*__\(root .*\)$/\1/p'`
if [ "$root_version" != "$root_version2" ]; then
  echo "Root versions do not match."
  echo $root_version
  echo $root_version2
  exit 1
fi
setup $root_version

# Build larlite first.

cd ${HOME_DIR}/srcs/larlite
source config/setup.sh || exit 1
export LARLITE_CXX=g++             # Use g++ instead of clang.
make -j$ncores || exit 1

# Assemble larlite ups product.

install_dir=${HOME_DIR}/install/larlite/$LARLITE_VERSION
subdir=`get-directory-name subdir ${QUAL}:${BUILDTYPE}`
flavor_dir=${install_dir}/$subdir
mkdir -p $flavor_dir
cp -r . $flavor_dir
cp -r ups $install_dir

# Declare larlite ups product in temporary products area.

if uname | grep -q Darwin; then
  flavor=`ups flavor -2`
else
  flavor=`ups flavor`
fi
ups declare -z ${HOME_DIR}/install -r larlite/$LARLITE_VERSION -m larlite.table -f $flavor -q ${QUAL}:${BUILDTYPE} -U ups larlite $LARLITE_VERSION

# Make distribution tarball

cd ${HOME_DIR}/install
dot_version=`echo $LARLITE_VERSION | sed -e 's/_/\./g' | sed -e 's/^v//'`
subdir=`echo $subdir | sed -e 's/\./-/g'`
#qual=`echo $CETPKG_QUAL | sed -e 's/:/-/g'`
tarballname=larlite-${dot_version}-${subdir}.tar.bz2
echo "Making ${tarballname}"
tar cjf ${HOME_DIR}/${tarballname} larlite

# Next build larcv.

cd ${HOME_DIR}/srcs/LArCV
source configure.sh || exit 1
export LARCV_CXX=g++             # Use g++ instead of clang.
make -j$ncores || exit 1

# Assemble larcv ups product.

install_dir=${HOME_DIR}/install/larcv/$LARCV_VERSION
subdir=`get-directory-name subdir ${QUAL}:${BUILDTYPE}`
flavor_dir=${install_dir}/$subdir
mkdir -p $flavor_dir
cp -r . $flavor_dir
cp -r ups $install_dir

# Declare larcv ups product in temporary products area.

if uname | grep -q Darwin; then
  flavor=`ups flavor -2`
else
  flavor=`ups flavor`
fi
ups declare -z ${HOME_DIR}/install -r larcv/$LARCV_VERSION -m larcv.table -f $flavor -q ${QUAL}:${BUILDTYPE} -U ups larcv $LARCV_VERSION

# Make distribution tarball

cd ${HOME_DIR}/install
dot_version=`echo $LARCV_VERSION | sed -e 's/_/\./g' | sed -e 's/^v//'`
subdir=`echo $subdir | sed -e 's/\./-/g'`
#qual=`echo $CETPKG_QUAL | sed -e 's/:/-/g'`
tarballname=larcv-${dot_version}-${subdir}.tar.bz2
echo "Making ${tarballname}"
tar cjf ${HOME_DIR}/${tarballname} larcv

# Save artifacts.

mv ${HOME_DIR}/*.bz2  $WORKSPACE/copyBack/ || exit 1
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
#rm -rf $WORKSPACE/temp || exit 1
set +x

exit 0
