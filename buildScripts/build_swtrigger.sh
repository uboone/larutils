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
if [ x$QUAL = xe9 ]; then
  setup gcc v4_9_3
elif [ x$QUAL = xe10 ]; then
  setup gcc v4_9_3a
else
  echo "Incorrect qualifier: $QUAL"
fi

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
git clone https://github.com/twongjirad/fememulator
cd fememulator

# Make sure repository is up to date and check out desired tag.

git checkout master
git pull
git checkout $VERSION

# Do post-checkout initialization.

source configure.sh

# Run cmake.

mkdir build
cd build
cmake .. -DCMAKE_CXX_COMPILER=`which g++` \
  -DCMAKE_CXX_FLAGS_DEBUG="-g -gdwarf-2 -O0" \
  -DCMAKE_CXX_FLAGS_PROF="-g -gdwarf-2 -O3" \
  -DCMAKE_BUILD_TYPE=$BUILDTYPE

# Run make

make -j$ncores

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

# Temprary.
# Ignore table file in source area and make our own.

rm $install_dir/ups/swtrigger.table
cat <<EOF > $install_dir/ups/swtrigger.table
File=Table 
Product=swtrigger
 
Group:

Flavor     = ANY
Qualifiers = "e9:prof"

  Action = GetFQDir
    if ( printenv CET_SUBDIR > /dev/null )
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/\${CET_SUBDIR}.e9.prof )
    else()
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/`get-directory-name subdir`.e9.prof )
    endif ( printenv CET_SUBDIR > /dev/null )
    fileTest( \${\${UPS_PROD_NAME_UC}_FQ_DIR}, -d, "\${\${UPS_PROD_NAME_UC}_FQ_DIR} directory not found: SETUP ABORTED")

  Action = GetProducts
    setupRequired( root v5_34_32 -q +e9:+nu:+prof )

Flavor     = ANY
Qualifiers = "e9:debug"

  Action = GetFQDir
    if ( printenv CET_SUBDIR > /dev/null )
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/\${CET_SUBDIR}.e9.debug )
    else()
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/`get-directory-name subdir`.e9.debug )
    endif ( printenv CET_SUBDIR > /dev/null )
    fileTest( \${\${UPS_PROD_NAME_UC}_FQ_DIR}, -d, "\${\${UPS_PROD_NAME_UC}_FQ_DIR} directory not found: SETUP ABORTED")

  Action = GetProducts
    setupRequired( root v5_34_32 -q +e9:+nu:+debug )

Flavor     = ANY
Qualifiers = "e9:opt"

  Action = GetFQDir
    if ( printenv CET_SUBDIR > /dev/null )
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/\${CET_SUBDIR}.e9.opt )
    else()
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/`get-directory-name subdir`.e9.opt )
    endif ( printenv CET_SUBDIR > /dev/null )
    fileTest( \${\${UPS_PROD_NAME_UC}_FQ_DIR}, -d, "\${\${UPS_PROD_NAME_UC}_FQ_DIR} directory not found: SETUP ABORTED")

  Action = GetProducts
    setupRequired( root v5_34_32 -q +e9:+nu:+opt )


Flavor     = ANY
Qualifiers = "e10:prof"

  Action = GetFQDir
    if ( printenv CET_SUBDIR > /dev/null )
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/\${CET_SUBDIR}.e10.prof )
    else()
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/`get-directory-name subdir`.e10.prof )
    endif ( printenv CET_SUBDIR > /dev/null )
    fileTest( \${\${UPS_PROD_NAME_UC}_FQ_DIR}, -d, "\${\${UPS_PROD_NAME_UC}_FQ_DIR} directory not found: SETUP ABORTED")

  Action = GetProducts
    setupRequired( root v6_06_04b -q +e10:+nu:+prof )

Flavor     = ANY
Qualifiers = "e10:debug"

  Action = GetFQDir
    if ( printenv CET_SUBDIR > /dev/null )
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/\${CET_SUBDIR}.e10.debug )
    else()
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/`get-directory-name subdir`.e10.debug )
    endif ( printenv CET_SUBDIR > /dev/null )
    fileTest( \${\${UPS_PROD_NAME_UC}_FQ_DIR}, -d, "\${\${UPS_PROD_NAME_UC}_FQ_DIR} directory not found: SETUP ABORTED")

  Action = GetProducts
    setupRequired( root v6_06_04b -q +e10:+nu:+debug )

Flavor     = ANY
Qualifiers = "e10:opt"

  Action = GetFQDir
    if ( printenv CET_SUBDIR > /dev/null )
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/\${CET_SUBDIR}.e10.opt )
    else()
      envSet( \${UPS_PROD_NAME_UC}_FQ_DIR, \${\${UPS_PROD_NAME_UC}_DIR}/`get-directory-name subdir`.e10.opt )
    endif ( printenv CET_SUBDIR > /dev/null )
    fileTest( \${\${UPS_PROD_NAME_UC}_FQ_DIR}, -d, "\${\${UPS_PROD_NAME_UC}_FQ_DIR} directory not found: SETUP ABORTED")

  Action = GetProducts
    setupRequired( root v6_06_04b -q +e10:+nu:+opt )


Common:
  Action = setup
    prodDir()
    setupEnv()
    envSet(\${UPS_PROD_NAME_UC}_VERSION, \${UPS_PROD_VERSION})

    # cetpkgsupport has get-directory-name and find-path
    # cetpkgsupport also defines the CET_SUBDIR variable
    setupRequired(cetpkgsupport)
    exeActionRequired(GetFQDir)

    # Set up required products, which is root
    exeActionRequired(GetProducts)

    #envSet(\${UPS_PROD_NAME_UC}_ROOT5,1)
    envSet(\${UPS_PROD_NAME_UC}_LIBDIR,\${\${UPS_PROD_NAME_UC}_FQ_DIR}/lib)
    envSet(\${UPS_PROD_NAME_UC}_INCDIR,\${UPS_PROD_DIR}/source)

    if ( test `uname` = "Darwin" )
      envSet(\${UPS_PROD_NAME_UC}_CXX,clang++)
      pathPrepend(DYLD_LIBRARY_PATH, \${\${UPS_PROD_NAME_UC}_LIBDIR})
    else()
      envSet(\${UPS_PROD_NAME_UC}_CXX,g++)
      pathPrepend(LD_LIBRARY_PATH, \${\${UPS_PROD_NAME_UC}_LIBDIR})
    endif ( test `uname` = "Darwin" )

    # add the bin directory to the path
    pathPrepend(PATH, \${UPS_PROD_DIR}/\${UPS_PROD_FLAVOR}/bin )
    # add the python area to the pythonpath
    pathPrepend(PYTHONPATH, \${UPS_PROD_DIR}/\${UPS_PROD_FLAVOR}/python )



End:
# End Group definition
#*************************************************
#
# ups declare command that works on gpvm:
# ups declare swtrigger v02_02_01 -r swtrigger/v02_02_01 -f Linux64bit+2.6-2.12 -m swtrigger.table -q e9:prof -U ups/
#
#
EOF

# Make a dbconfig file.

cat <<EOF > ${SWTRIGGER_HOME_DIR}/install/.upsfiles/dbconfig
FILE = DBCONFIG
AUTHORIZED_NODES = *
VERSION_SUBDIR = 1
PROD_DIR_PREFIX = \${UPS_THIS_DB}
UPD_USERCODE_DIR = \${UPS_THIS_DB}/.updfiles
EOF

# Declare ups product in temporary products area.

flavor=`ups flavor`
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
