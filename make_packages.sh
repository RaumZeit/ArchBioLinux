#!/bin/bash
#

#REPO_DIR=/path/to/your/repo
REPO_DIR=/media/oberon/projects/ArchLinux/repo
REPO_DB=${REPO_DIR}/i686/repo.db.tar.gz
REPO_DB64=${REPO_DIR}/x86_64/repo.db.tar.gz

set -e

for i in *;do
  if [ -d $i ]; then
    if [ -f $i/PKGBUILD ]; then
      cd $i;

      # update from aur.archlinux.org git repo
      if [ -d .git ] ; then
        if [[ "$*" == *--update* ]] ; then
          echo "updating git repo"
          git pull
        fi
      fi

      # make x64 package
      if [[ ! "$*" == *--no-x86_64* ]] ; then
        makepkg -Cfsc
        if [[ "$*" == *--repo-add* ]] ; then
          for j in *x86_64.pkg.tar.xz; do
            cp $j ${REPO_DIR}/x86_64/
            repo-add ${REPO_DB64} ${REPO_DIR}/x86_64/$j
          done
        fi
      fi


      # make i686 package
      if [[ ! "$*" == *--no-i686* ]] ; then
        linux32 makepkg -Cfsc --config ~/.makepkg.i686.conf

        if [[ "$*" == *--repo-add* ]] ; then
          # move and add files to the repo
          for j in *i686.pkg.tar.xz; do
            cp $j ${REPO_DIR}/i686/
            repo-add ${REPO_DB} ${REPO_DIR}/i686/$j
          done
        fi
      fi

      cd ..
    fi
  fi
done
