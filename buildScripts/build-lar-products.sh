#!/bin/bash

# build "third party" products

usage()
{
  cat 1>&2 <<EOF
Usage: $(basename ${0}) [-h]
       $(basename ${0}) <version> <qual_set> <build_type>

Options:

  -h    This help.

Arguments:

  qual_set         Supported qualifier sets: e9, e10, e14

EOF
}

while getopts :h OPT; do
  case ${OPT} in
    h)
      usage
      exit 1
      ;;
    *)
      usage
      exit 1
  esac
done
shift `expr $OPTIND - 1`
OPTIND=1

working_dir=${WORKSPACE}
version=${LARVER}
qual_set="${QUAL}"
build_type=${BUILDTYPE}

case ${build_type} in
  debug) ;;
  prof) ;;
  *)
    usage
    exit 1
esac

d14_ok=true
d16_ok=true
basequal=${qual_set}

case ${qual_set} in
  e9) d16_ok=false ;;
  e10) d16_ok=false ;;
  e14) ;;
  e15) ;;
  c2) d14_ok=false ;;
  *)
    usage
    exit 1
esac

# create copyBack so artifact copy does not fail on early exit
rm -rf $WORKSPACE/copyBack 
mkdir -p $WORKSPACE/copyBack || exit 1

# check XCode
if [[ `uname -s` == Darwin ]] 
then
  OSnum=`uname -r | cut -f1 -d"."`
  xver=`xcodebuild -version | grep Xcode | cut -f2 -d" " | cut -f1 -d"."`
  xcver=`xcodebuild -version | grep Xcode`
  if [[ ${basequal} == e9 ]] && [[ ${xver} < 7 ]] && [[ ${OSnum} > 13 ]]
  then
    echo "${basequal} build not supported on `uname -s`${OSnum} with ${xcver}"
    echo "${basequal} build not supported on `uname -s`${OSnum} with ${xcver}" > $WORKSPACE/copyBack/skipping_build
    exit 0
  elif [[ ${basequal} == e1[04] ]] && [[ ${xver} < 7 ]] && [[ ${OSnum} > 13 ]]
  then
    echo "${basequal} build not supported on `uname -s`${OSnum} with ${xcver}"
    echo "${basequal} build not supported on `uname -s`${OSnum} with ${xcver}" > $WORKSPACE/copyBack/skipping_build
    exit 0
  elif [[ ${basequal} == e1[045] ]] && [[ ${OSnum} > 16 ]]
  then
    echo "${basequal} build not supported on `uname -s`${OSnum}"
    echo "${basequal} build not supported on `uname -s`${OSnum}" > $WORKSPACE/copyBack/skipping_build
    exit 0
  fi
  if [[ ${d16_ok} == false ]] && [[ ${OSnum} > 15 ]]
  then
    echo "${basequal} build not supported on `uname -s`${OSnum}"
    echo "${basequal} build not supported on `uname -s`${OSnum}" > $WORKSPACE/copyBack/skipping_build
    exit 0
  fi
  # using this to disable unsupported El Capitan c2 builds
  if [[ ${d14_ok} == false ]] && [[ ${OSnum} < 16 ]]
  then
    echo "${basequal} build not supported on `uname -s`${OSnum}"
    echo "${basequal} build not supported on `uname -s`${OSnum}" > $WORKSPACE/copyBack/skipping_build
    exit 0
  fi
fi

dotver=`echo ${version} | sed -e 's/_/./g' | sed -e 's/^v//'`

echo "building the larsoft product stack for ${version} ${dotver} ${qual_set} ${build_type}"

OS=`uname`
if [ "${OS}" = "Linux" ]
then
  id=`lsb_release -is`
  if [ "${id}" = "Ubuntu" ]
  then
    flvr=u`lsb_release -r | sed -e 's/[[:space:]]//g' | cut -f2 -d":" | cut -f1 -d"."`
  else
    flvr=slf`lsb_release -r | sed -e 's/[[:space:]]//g' | cut -f2 -d":" | cut -f1 -d"."`
  fi
elif [ "${OS}" = "Darwin" ]
then
  flvr=d`uname -r | cut -f1 -d"."`
else 
  echo "ERROR: unrecognized operating system ${OS}"
  exit 1
fi
echo "build flavor is ${flvr}"
echo ""

qualdir=`echo ${qual_set} | sed -e 's%:%-%'`

set -x

blddir=${working_dir}/build
srcdir=${working_dir}/source
# start with clean directories
rm -rf ${blddir}
rm -rf ${srcdir}
# now make the dfirectories
mkdir -p ${srcdir} || exit 1
mkdir -p ${blddir} || exit 1

cd ${blddir} || exit 1
curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/bundles/tools/buildFW || exit 1
chmod +x buildFW

cd ${blddir} || exit 1
echo
echo "begin build"
echo
./buildFW -t -b ${qual_set} ${blddir} ${build_type} lar_product_stack-${version} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }

echo
echo "move files"
echo
mv ${blddir}/*source* ${srcdir}/
mv ${blddir}/g*noarch* ${srcdir}/
mv ${blddir}/*.bz2  $WORKSPACE/copyBack/
mv ${blddir}/*.txt  $WORKSPACE/copyBack/
echo
echo "cleanup"
echo
rm -rf ${srcdir}
rm -rf ${blddir}

exit 0
