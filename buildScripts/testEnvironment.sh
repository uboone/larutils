#!/bin/bash

# silly little script to check the build environment

echo $BUILDTYPE
echo $LARVER
echo $WORKSPACE

pwd

set -x
ls
ls /cvmfs/oasis.opensciencegrid.org/fermilab/products/
ls /grid/fermiapp/products

exit 0
