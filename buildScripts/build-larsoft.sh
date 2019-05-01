#!/bin/bash

# pull source code in $WORKSPACE/source
# build in $WORKSPACE/build
# copyback directory is $WORKSPACE/copyBack

usage()
{
  cat 1>&2 <<EOF
Usage: $(basename ${0}) [-h]
       env WORKSPACE=<workspace> LARVER=<larsoft version> LAROBJ=<larsoftobj version> QUAL=<qualifier> BUILDTYPE=<debug|prof> $(basename ${0}) 

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

oIFS=${IFS}; IFS=:; quals=(${qual_set//-/:}); IFS=$oIFS; unset oIFS
for onequal in "${quals[@]}"; do
  case ${onequal} in
    e[679]|e1[0-9]|c[0-9])
      basequal=${onequal}
      ;;
    s7[0-9]|s8[0-9])
      squal=${onequal}
      ;;
    *)
      labels+=${onequal}
  esac
done

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

# Check supported builds.
if [[ `uname -s` == Darwin ]]; then
  OSnum=`uname -r | cut -f1 -d"."`
  xver=`xcodebuild -version | grep Xcode | cut -f2 -d" " | cut -f1 -d"."`
  xcver=`xcodebuild -version | grep Xcode`
  if { [[ ${basequal} =~ ^e(9$|[1-9][0-9]) ]] && \
    [[ ${xver} < 7 ]] && \
    [[ ${OSnum} > 13 ]]; }; then
    # XCode too old on this platform.
    echo "${basequal} build not supported on `uname -s`${OSnum} with ${xcver}"
    echo "${basequal} build not supported on `uname -s`${OSnum} with ${xcver}" > \
      "${working_dir}/copyBack/skipping_build"
    exit 0
  elif { [[ "$basequal" == e* ]] || \
    { [[ "$basequal" == c* ]] && (( $OSnum < 15 )); }; }; then
    if want_unsupported; then
      echo "Building unsupported ${basequal} on `uname -s`${OSnum} due to \$CET_BUILD_UNSUPPORTED=${CET_BUILD_UNSUPPORTED}"
    else
      # Don't normally support GCC builds on MacOS.
      msg="${basequal} build not supported on `uname -s`${OSnum} -- export CET_BUILD_UNSUPPORTED=1 to override."
      echo "$msg"
      echo "$msg" > "${working_dir}/copyBack/skipping_build"
      exit 0
    fi
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
    if [ "${flvr}" = "u14" ]; then
      export UPS_OVERRIDE="-H Linux64bit+3.19-2.19"
    fi
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
