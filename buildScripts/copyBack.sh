#!/bin/bash

# copy the artifacts from buildUboone.sh

## https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=debug,label1=swarm,label2=SLF5/lastSuccessfulBuild/artifact/copyBack/uboonecode-03.01.00-slf5-x86_64-e6-debug.tar.bz2
## https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=debug,label1=swarm,label2=SLF5/lastSuccessfulBuild/artifact/copyBack/ubutil-01.03.00-slf5-x86_64-e6-debug.tar.bz2

## https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=prof,label1=swarm,label2=SLF5/lastSuccessfulBuild/artifact/copyBack/uboonecode-03.01.00-slf5-x86_64-e6-prof.tar.bz2
## https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=prof,label1=swarm,label2=SLF5/lastSuccessfulBuild/artifact/copyBack/ubutil-01.03.00-slf5-x86_64-e6-prof.tar.bz2

## https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=debug,label1=swarm,label2=SLF6/lastSuccessfulBuild/artifact/copyBack/uboonecode-03.01.00-slf6-x86_64-e6-debug.tar.bz2
## https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=debug,label1=swarm,label2=SLF6/lastSuccessfulBuild/artifact/copyBack/ubutil-01.03.00-slf6-x86_64-e6-debug.tar.bz2

## https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=prof,label1=swarm,label2=SLF6/lastSuccessfulBuild/artifact/copyBack/uboonecode-03.01.00-slf6-x86_64-e6-prof.tar.bz2
## https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=prof,label1=swarm,label2=SLF6/lastSuccessfulBuild/artifact/copyBack/ubutil-01.03.00-slf6-x86_64-e6-prof.tar.bz2

tmpdir=/tmp/buildArtifacts$$$$

set -x

mkdir -p ${tmpdir} || exit 1
cd ${tmpdir} || exit 1
curl -O https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=debug,label1=swarm,label2=SLF5/lastSuccessfulBuild/artifact/copyBack/*zip*/copyBack.zip
unzip copyBack.zip
curl -O https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=prof,label1=swarm,label2=SLF5/lastSuccessfulBuild/artifact/copyBack/*zip*/copyBack.zip
unzip copyBack.zip
curl -O https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=debug,label1=swarm,label2=SLF6/lastSuccessfulBuild/artifact/copyBack/*zip*/copyBack.zip
unzip copyBack.zip
curl -O https://buildmaster.fnal.gov/view/LArSoft/job/build-uboonecode/BUILDTYPE=prof,label1=swarm,label2=SLF6/lastSuccessfulBuild/artifact/copyBack/*zip*/copyBack.zip
unzip copyBack.zip

ls ${tmpdir}

set +x

exit 0
