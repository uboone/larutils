#!/bin/bash

# pull source code in $WORKSPACE/source
# build in $WORKSPACE/build
# copyback directory is $WORKSPACE/copyBack

usage()
{
  cat 1>&2 <<EOF
Usage: $(basename ${0}) [-h]
       $(basename ${0}) <version> <qual_set> <build_type>

Options:

  -h    This help.

Arguments:

  qual_set         Supported qualifier sets: s8:e7, s11:e7

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

case ${qual_set} in
  s5:e5) 
     basequal=e5
     squal=s5
     artver=v1_12_04
     nuver=v1_07_00
  ;;
  s5:e6) 
     basequal=e6
     squal=s5
     artver=v1_12_04
     nuver=v1_07_00
  ;;
  s6:e6) 
     basequal=e6
     squal=s6
     artver=v1_12_05
     nuver=v1_07_01
  ;;
  s7:e7) 
     basequal=e7
     squal=s7
     artver=v1_13_01
     nuver=v1_09_01
  ;;
  s8:e7) 
     basequal=e7
     squal=s8
     artver=v1_13_02
     nuver=v1_10_02
  ;;
  s11:e7) 
     basequal=e7
     squal=s11
     artver=v1_14_02
     nuver=v1_11_01
  ;;
  s12:e7) 
     basequal=e7
     squal=s12
     artver=v1_14_03
     nuver=v1_13_01
  ;;
  s14:e7) 
     basequal=e7
     squal=s14
     artver=v1_15_01
     nuver=v1_14_01
  ;;
  s15:e7) 
     basequal=e7
     squal=s15
     artver=v1_15_02
     nuver=v1_14_02
  ;;
  *)
    usage
    exit 1
esac

case ${build_type} in
  debug) ;;
  prof) ;;
  *)
    usage
    exit 1
esac

dotver=`echo ${version} | sed -e 's/_/./g' | sed -e 's/^v//'`

echo "building the larsoft base distribution for ${version} ${dotver} ${qual_set} ${build_type}"

OS=`uname`
if [ "${OS}" = "Linux" ]
then
  flvr=slf`lsb_release -r | sed -e 's/[[:space:]]//g' | cut -f2 -d":" | cut -f1 -d"."`
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

srcdir=${working_dir}/source
mkdir -p ${srcdir} || exit 1
# make sure we have a clean build directory
blddir=${working_dir}/build
rm -rf ${blddir}
mkdir -p ${blddir} || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1

cd ${blddir} || exit 1
curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/bundles/tools/pullProducts || exit 1
chmod +x pullProducts
# source code tarballs MUST be pulled first
./pullProducts ${blddir} source artbase-${artver} || \
      { cat 1>&2 <<EOF
ERROR: pull of artbase-${artver} source failed
EOF
        exit 1
      }
./pullProducts ${blddir} source larsoft-${version} || \
      { cat 1>&2 <<EOF
ERROR: pull of art-${version} failed
EOF
        exit 1
      }
mv ${blddir}/*source* ${srcdir}/

cd ${blddir} || exit 1
# pulling binaries is allowed to fail
./pullProducts ${blddir} ${flvr} art-${artver} ${basequal} ${build_type} 
./pullProducts ${blddir} ${flvr} nu-${nuver} ${squal}-${basequal} ${build_type} 
echo
echo "begin build"
echo
./buildFW -t -b ${basequal} -s ${squal} ${blddir} ${build_type} larsoft-${version} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }

echo
echo "move files"
echo
mv ${blddir}/*.bz2  $WORKSPACE/copyBack/
mv ${blddir}/*.txt  $WORKSPACE/copyBack/
mv ${blddir}/*.log  $WORKSPACE/copyBack/

exit 0
