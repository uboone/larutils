#!/bin/bash

# make a distribution tarball for larsoft_data, uboone_data, etc.

usage()
{
  cat 1>&2 <<EOF
Usage: $(basename ${0}) [-h]
       $(basename ${0}) <options> <product_topdir> <product_name> <product_version>

Options:

  -h    This help.

Arguments:

  product_topdir   Top directory for relocatable-UPS products area.
  product_name     Product name, e.g., larsoft_data
  product_version  Product version, e.g., v0_03_01

Notes: 
  The tarball will be made in the directory you are in when the script is called.
  $(basename ${0}) is suitable for use with larsoft_data, not other products.

EOF
}

########################################################################
# Main body.

while getopts :fh OPT; do
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

product_topdir=${1}
product_name=${2}
product_version=${3}

working_dir=$(/bin/pwd)
dotver=`echo ${product_version} | sed -e 's/_/./g' | sed -e 's/^v//'`

if [ -z ${product_topdir} ]
then
   usage
   exit 1
fi

if [ -z ${product_name} ]
then
   usage
   exit 1
fi
if [ -z ${product_version} ]
then
   usage
   exit 1
fi

[[ -n "$working_dir" ]] && \
  [[ -d "${working_dir}" ]] && \
  [[ -w "${working_dir}" ]] || \
  { echo "ERROR: Could not write to specified working directory \"${working_dir}\"." 1>&2; exit 1; }

[[ -d ${product_topdir}/${product_name}/${product_version} ]] || \
  { echo "ERROR: ${product_topdir}/${product_name}/${product_version} is not a directory." 1>&2; exit 1; }
[[ -d ${product_topdir}/${product_name}/${product_version}.version ]] || \
  { echo "ERROR: ${product_topdir}/${product_name}/${product_version}.version is not a directory." 1>&2; exit 1; }

set -x
cd ${product_topdir}
tar cjf ${working_dir}/${product_name}-${dotver}-noarch.tar.bz2 \
        ${product_name}/${product_version}.version  \
	${product_name}/${product_version}
cd ${working_dir}
ls -l ${product_name}-${dotver}-noarch.tar.gz || exit 1
set +x

exit 0
