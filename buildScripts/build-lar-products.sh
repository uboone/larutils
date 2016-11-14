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

  qual_set         Supported qualifier sets: e9, e10, e12

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

# check XCode
if [[ `uname -s` == Darwin ]] 
then
  OSnum=`uname -r | cut -f1 -d"."`
  xver=`xcodebuild -version | grep Xcode | cut -f2 -d" " | cut -f1 -d"."`
  xcver=`xcodebuild -version | grep Xcode`
  if [[ ${basequal} == e9 ]] && [[ ${xver} < 7 ]] && [[ ${OSnum} > 13 ]]
  then
  echo "${basequal} build not supported on `uname -s`${OSnum} with ${xcver}"
  exit 0
  fi
fi

dotver=`echo ${version} | sed -e 's/_/./g' | sed -e 's/^v//'`

echo "building the larbase base distribution for ${version} ${dotver} ${qual_set} ${build_type}"

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
rm -rf $WORKSPACE/copyBack 
# now make the dfirectories
mkdir -p ${srcdir} || exit 1
mkdir -p ${blddir} || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1

cd ${blddir} || exit 1
curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/bundles/tools/pullProducts || exit 1
chmod +x pullProducts
# source code tarballs MUST be pulled first
./pullProducts ${blddir} source lar_product_stack-${version} || \
      { cat 1>&2 <<EOF
ERROR: pull of lar_product_stack-${version} source failed
EOF
        exit 1
      }
mv ${blddir}/*source* ${srcdir}/

cd ${blddir} || exit 1
echo
echo "begin build"
echo
${WORKSPACE}/artutilscripts/tools/newBuild -t -b ${qual_set} ${blddir} ${build_type} lar_product_stack-${version} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }

echo
echo "move files"
echo
mv ${blddir}/*.bz2  $WORKSPACE/copyBack/
mv ${blddir}/*.txt  $WORKSPACE/copyBack/
rm -rf ${srcdir}
rm -rf ${blddir}

exit 0
