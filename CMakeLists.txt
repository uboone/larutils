# CMakeLists.txt file for larutils

#  This simply copies files into an install directory - there is no build

CMAKE_MINIMUM_REQUIRED (VERSION 2.8)

project(larutils NONE)

# cetbuildtools contains our cmake modules
set( CETBUILDTOOLS_VERSION $ENV{CETBUILDTOOLS_VERSION} )
if( NOT CETBUILDTOOLS_VERSION )
  message( FATAL_ERROR "ERROR: setup cetbuildtools to get the cmake modules" )
endif()
set( CMAKE_MODULE_PATH $ENV{CETBUILDTOOLS_DIR}/Modules ${CMAKE_MODULE_PATH} )

include(CetCMakeEnv)

# larutils has no architecture dependence
cet_cmake_env( noarch )

# Make sure cetbuildtools is set up (version is minimum)
find_ups_product(cetbuildtools v4_00_00)

# source code
add_subdirectory(buildScripts)
add_subdirectory(test)
add_subdirectory(ups)

# packaging utility
include(UseCPack)


