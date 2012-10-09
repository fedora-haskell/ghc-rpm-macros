#!/bin/sh

set -e

PKG=$1

[ -d "$PKG" -o -f "$PKG.spec" ] || fedpkg clone -a $PKG

[ -d "$PKG" ] && cd $PKG

ARCH=$(arch)

#if [ -d $ARCH ]; then
#  echo Please move existing $ARCH/
#  exit 1
#fi

if [ -n "$2" ]; then
  fedpkg switch-branch $2
fi

sudo yum-builddep $PKG.spec

fedpkg local

VERREL=$(fedpkg verrel | sed -e "s/^$PKG-//")

TMP=test-tmp

mkdir -p $TMP/

cd $ARCH

PKGS=$(rpm -qp $(ls *-$VERREL*.rpm))

for i in $PKGS; do
  sudo yum install -q $i
  for k in list requires provides; do
    rpm -qp --$k $i.rpm | grep -v rpmlib > ../$TMP/$i.$k.test
    rpm -q --$k $i | grep -v rpmlib > ../$TMP/$i.$k.installed
    diff -u ../$TMP/$i.$k.installed ../$TMP/$i.$k.test || :
  done
done