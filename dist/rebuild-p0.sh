#!/bin/bash
#
# Rebuild a student distribution:
#   * copy files from reference solution into temporary folder
#   * remove solutions and enable boilerplate code
#   * generate tarball and zip file
#
# Mike Lam, James Madison University, Fall 2016
#

# Allow extended globbing
shopt -s extglob

function cleanup {
    sed -e '/BEGIN_SOLUTION/,/END_SOLUTION/d' "$REF/$1" >tmp
    sed -e 's/\/\/ BOILERPLATE: //g' tmp >$ROOT/$1
    rm tmp
}

# paths
ROOT=p0-intro
REF=../ref/p0-intro

# set up distribution folder
rm -rf $ROOT
mkdir $ROOT
mkdir $ROOT/tests
mkdir $ROOT/tests/inputs
mkdir $ROOT/tests/expected

# rebuild
make -C $REF clean
make -C $REF

# generic files
cleanup "Makefile"
cleanup "main.c"

# project-specific files
cleanup "p0-intro.h"
cleanup "p0-intro.c"

# testsuite
cleanup "tests/testsuite.c"

make -C $REF/tests
cp -H $REF/tests/public.c          $ROOT/tests/
cp -H $REF/tests/integration.sh    $ROOT/tests/
cp -H $REF/tests/inputs/!(*_H.*)   $ROOT/tests/inputs/
cp -H $REF/tests/expected/!(*_H.*) $ROOT/tests/expected/
cp -H $REF/tests/itests.*          $ROOT/tests/
cp -H $REF/tests/private.o         $ROOT/tests/
strip -S $ROOT/tests/private.o
cat $REF/tests/Makefile | sed -e '/^MODS/d' | sed -e 's/^#MODS/MODS/g' \
                        | sed -e '/^OBJS/d' | sed -e 's/^#OBJS/OBJS/g' >$ROOT/tests/Makefile

cleanup "tests/itests.include"

# build tarball and zip file
tar -zchvf $ROOT.tar.gz $ROOT

# create solution folder (for testing)
rm -rf $ROOT-soln
cp -r $ROOT $ROOT-soln
cp -H $REF/main.c                  $ROOT-soln/
cp -H $REF/p0-intro.c              $ROOT-soln/

