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
objver=${LAROBJ}

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
     nuver=v1_14_05
  ;;
  s18:e7) 
     basequal=e7
     squal=s18
     artver=v1_16_02
     nuver=v1_15_02
  ;;
  s18:e9) 
     basequal=e9
     squal=s18
     artver=v1_16_02
     nuver=v1_15_02
  ;;
  s20:e9) 
     basequal=e9
     squal=s20
     artver=v1_17_02
     nuver=v1_16_00
     oldver=v04_28_00
  ;;
  s21:e9) 
     basequal=e9
     squal=s21
     artver=v1_17_03
     nuver=v1_16_01
     oldver=v04_29_00
  ;;
  s24:e9)
     basequal=e9
     squal=s24
     artver=v1_17_04
     nuver=v1_17_01
     oldver=v04_30_02
  ;;
  s26:e9)
     basequal=e9
     squal=s26
     artver=v1_17_05
     nuver=v1_19_00
     oldver=v04_31_00
  ;;
  s28:e9)
     basequal=e9
     squal=s28
     artver=v1_17_06
     nuver=v1_20_03
     oldver=v04_32_01
  ;;
  s30:e9)
     basequal=e9
     squal=s30
     artver=v1_17_07
     nuver=v1_24_05
     oldver=v05_15_00
  ;;
  s31:e9)
     basequal=e9
     squal=s31
     artver=v1_18_05
     nuver=v1_25_01
     oldver=v05_08_00
  ;;
  s33:e10)
     basequal=e10
     squal=s33
     artver=v2_00_02
     nuver=v2_00_00
     oldver=v06_00_00_rc4
  ;;
  s36:e10)
     basequal=e10
     squal=s36
     artver=v2_00_03
     nuver=v2_01_03
     oldver=v06_01_00
  ;;
  s39:e10)
     basequal=e10
     squal=s39
     artver=v2_02_02
     nuver=v2_03_00
     oldver=v06_03_00
  ;;
  s41:e10)
     basequal=e10
     squal=s41
     artver=v2_03_00
     nuver=v2_03_01
     oldver=v06_05_00
  ;;
  s42:e10)
     basequal=e10
     squal=s42
     artver=v2_04_00
     nuver=v2_05_00
     oldver=v06_07_00
  ;;
  s43:e10)
     basequal=e10
     squal=s43
     artver=v2_05_00
     nuver=v2_06_02
     oldver=v06_12_00
  ;;
  s44:e10)
     basequal=e10
     squal=s44
     artver=v2_04_01
     nuver=v2_06_01
     oldver=v06_11_00
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

echo "building the larsoft base distribution for ${version} ${dotver} ${qual_set} ${build_type}"

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
# pulling nubase source for the different git version
./pullProducts ${blddir} source nubase-${nuver} || \
      { cat 1>&2 <<EOF
ERROR: pull of nubase-${nuver} source failed
EOF
        exit 1
      }
./pullProducts ${blddir} source larbase-${version} || \
      { cat 1>&2 <<EOF
ERROR: pull of larbase-${version} source failed
EOF
        exit 1
      }
if [[ ${objver} != "none" ]]; then
./pullProducts ${blddir} source larsoftobj-${objver} || \
      { cat 1>&2 <<EOF
ERROR: pull of larsoftobj-${objver} source failed
EOF
        exit 1
      }
fi
./pullProducts ${blddir} source larsoft-${version} || \
      { cat 1>&2 <<EOF
ERROR: pull of larsoft-${version} failed
EOF
        exit 1
      }
mv ${blddir}/*source* ${srcdir}/

cd ${blddir} || exit 1
echo
echo "begin build"
echo
${WORKSPACE}/artutilscripts/tools/newBuild -t -b ${basequal} ${blddir} ${build_type} lar_product_stack-${version} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }
${WORKSPACE}/artutilscripts/tools/newBuild -t -b ${basequal} -s ${squal} ${blddir} ${build_type} larbase-${version} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }
if [[ ${objver} != "none" ]]; then
${WORKSPACE}/artutilscripts/tools/newBuild -t -b ${basequal} ${blddir} ${build_type} larsoftobj-${objver} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }
fi
${WORKSPACE}/artutilscripts/tools/newBuild -t -b ${basequal} -s ${squal} ${blddir} ${build_type} larsoft-${version} || \
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
