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

d16_ok=false

case ${qual_set} in
  s5:e5) 
     basequal=e5
     squal=s5
  ;;
  s5:e6) 
     basequal=e6
     squal=s5
  ;;
  s6:e6) 
     basequal=e6
     squal=s6
  ;;
  s7:e7) 
     basequal=e7
     squal=s7
  ;;
  s8:e7) 
     basequal=e7
     squal=s8
  ;;
  s11:e7) 
     basequal=e7
     squal=s11
  ;;
  s12:e7) 
     basequal=e7
     squal=s12
  ;;
  s14:e7) 
     basequal=e7
     squal=s14
  ;;
  s15:e7) 
     basequal=e7
     squal=s15
  ;;
  s18:e7) 
     basequal=e7
     squal=s18
  ;;
  s18:e9) 
     basequal=e9
     squal=s18
  ;;
  s20:e9) 
     basequal=e9
     squal=s20
  ;;
  s21:e9) 
     basequal=e9
     squal=s21
  ;;
  s24:e9)
     basequal=e9
     squal=s24
  ;;
  s26:e9)
     basequal=e9
     squal=s26
  ;;
  s28:e9)
     basequal=e9
     squal=s28
  ;;
  s30:e9)
     basequal=e9
     squal=s30
  ;;
  s31:e9)
     basequal=e9
     squal=s31
  ;;
  s33:e10)
     basequal=e10
     squal=s33
  ;;
  s36:e10)
     basequal=e10
     squal=s36
  ;;
  s39:e10)
     basequal=e10
     squal=s39
  ;;
  s41:e10)
     basequal=e10
     squal=s41
  ;;
  s42:e10)
     basequal=e10
     squal=s42
  ;;
  s43:e10)
     basequal=e10
     squal=s43
  ;;
  s44:e10)
     basequal=e10
     squal=s44
  ;;
  s46:e10)
     basequal=e10
     squal=s46
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
  fi
  if [[ ${d16_ok} == false ]] && [[ ${OSnum} > 15 ]]
  then
    echo "${basequal} build not supported on `uname -s`${OSnum}"
    echo "${basequal} build not supported on `uname -s`${OSnum}" > $WORKSPACE/copyBack/skipping_build
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
    export UPS_OVERRIDE="-H Linux64bit+3.19-2.19"
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
curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/bundles/tools/pullProducts || exit 1
chmod +x pullProducts
# source code tarballs MUST be pulled first
./pullProducts ${blddir} source lar_product_stack-${version} || \
      { cat 1>&2 <<EOF
ERROR: pull of lar_product_stack-${version} source failed
EOF
        exit 1
      }
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
./buildFW -t -b ${basequal} ${blddir} ${build_type} lar_product_stack-${version} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }
./buildFW -t -b ${basequal} -s ${squal} ${blddir} ${build_type} larbase-${version} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }
if [[ ${objver} != "none" ]]; then
./buildFW -t -b ${basequal} ${blddir} ${build_type} larsoftobj-${objver} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }
fi
./buildFW -t -b ${basequal} -s ${squal} ${blddir} ${build_type} larsoft-${version} || \
 { mv ${blddir}/*.log  $WORKSPACE/copyBack/
   exit 1 
 }

echo
echo "move files"
echo
# get these out of the way
mv ${blddir}/*source* ${srcdir}/
mv ${blddir}/g*noarch* ${srcdir}/
mv ${blddir}/larsoft_data*.bz2 ${srcdir}/
# 
mv ${blddir}/*.bz2  $WORKSPACE/copyBack/
mv ${blddir}/*.txt  $WORKSPACE/copyBack/
rm -rf ${srcdir}
rm -rf ${blddir}

exit 0
