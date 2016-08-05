#!/usr/bin/env bash

# Usage function
function usage() {
  echo "$(basename $0) [-h] -t <modules|authors|code|this_year> <directory list>"
  echo "        search the listed directories for information"
}

# Determine command options (just -h for help)
while getopts "h:t:" OPTION
do
    case $OPTION in
        h   ) usage ; exit 0 ;;
	t   ) type=$OPTARG ;;
        *   ) echo "ERROR: Unknown option" ; usage ; exit 1 ;;
    esac
done
shift $((OPTIND - 1))


if [ -z "${type}" ]
then
    echo 'ERROR: no type specified'
    usage
    exit 1
fi

# can we find the code?
if [ $# -lt 1 ]; then
    echo "ERROR: Please specify a list of directories"
    usage
    exit 1
fi
directory_list=$@
for REP in ${directory_list}
do 
  if [ ! -d ${REP} ]; then
     echo "ERROR: ${REP} is not a directory"
     exit 1
  fi
  if [ ! -d ${REP}/.git ]; then
    echo "ERROR: cannot find ${REP}/.git"
    echo "ERROR: ${REP} must be the top of a git repository"
    exit 1
  fi
  ##echo "will search ${REP} for ${type}"
done

# now get the info
thisdir=`pwd`
##echo "we are here: ${thisdir}"
if [ "${type}" = "modules" ]; then
  for REP in ${directory_list}; do
    listm=`find ${REP} -name "*_*.cc" | grep -v test`
    module_list=`echo ${module_list} ${listm}`
  done
  num_mod=`echo ${module_list} | wc -w`
  ##echo ${module_list}
  echo "found ${num_mod} modules"
elif [ "${type}" = "authors" ]; then
  for REP in ${directory_list}; do
    cd ${REP}
    lista=`git log --all --format='"%cN"' | sort -u`
    author_list=`echo ${author_list} ${lista}`
    cd ${thisdir}
    echo "${lista}"
  done
  ##echo ${author_list}
elif [ "${type}" = "code" ]; then
  if [[ `type cloc` ]]; then
    echo "lines of code excluding fcl files and anything in the ups directory"
    cloc --exclude-dir=ups ${directory_list}
  else
    echo "ERROR: cannot find the cloc utilitiy"
    exit 1
  fi
elif [ "${type}" = "this_year" ]; then
  for REP in ${directory_list}; do
    cd ${REP}
    listy=`git log --pretty='' --numstat --since 1.year origin/master | grep -v '-' | grep -v ups | cut -f 1 | paste -sd+ - | bc`
    cd ${thisdir}
    echo "${REP}: ${listy} lines changed in the last year"
  done
else
  echo "ERROR: unrecognized type ${type}"
fi

exit 0
