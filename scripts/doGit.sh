#!/usr/bin/env bash

# run simple git commands on each repository in MRB_SOURCE


# Determine this command name
thisComFull=$(basename $0)
##thisCom=${thisComFull%.*}
fullCom="${thisComFull%.*}"

# Usage function
function usage() {
    echo "Usage: $fullCom <command>"
}

# Determine command options (just -h for help)
while getopts ":h" OPTION
do
    case $OPTION in
        h   ) usage ; exit 0 ;;
        *   ) echo "ERROR: Unknown option" ; usage ; exit 1 ;;
    esac
done

# Capture the tag
gitcmd=${1}
if [ -z "${gitcmd}" ]
then
    echo 'ERROR: no options specified'
    usage
    exit 1
fi


if [ -z "${MRB_SOURCE}" ]
then
    echo 'ERROR: MRB_SOURCE must be defined'
    echo '       source the appropriate localProductsXXX/setup'
    exit 1
fi

if [ ! -r $MRB_SOURCE/CMakeLists.txt ]; then
    echo "$MRB_SOURCE/CMakeLists.txt not found"
    exit 1
fi

# find the directories
# ignore any directory that does not contain ups/product_deps
list=`ls $MRB_SOURCE -1`
for file in $list
do
   if [ -d $file ]
   then
     if [ -r $file/ups/product_deps ]
     then
       pkglist="$file $pkglist"
     fi
   fi
done

  for REP in $pkglist
  do
     echo
     echo "${REP}: git ${gitcmd}"
     cd ${MRB_SOURCE}/${REP} || exit 1
     git ${gitcmd}
     okflow=$?
     if [ ! ${okflow} ]
     then
	echo "${REP} git ${gitcmd} failure: ${okflow}"
	exit 1
     fi
  done

exit 0
