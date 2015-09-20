#!/bin/bash
#

#REPO_DIR=/path/to/your/repo
REPO_DIR="/home/ronny/ArchRepo/ArchBio"

set -e

CWD=`pwd`
PKGBUILD_PARSER="${CWD}/pkgbuild-parse.sh"
LOGFILE="${CWD}/packages.log"
CONFIG32="${CWD}/.makepkg.i686.conf"

make_commands="-sr --noprogressbar" # install missing dependencies

BUILD=1
UPDATE=0
ADD_TO_REPO=0
CLEAN_BEFORE=1
CLEAN_AFTER=1
MAKE_64=1
MAKE_32=1
NOSKIP=0

#
# process commandline parameter flags
#

if [[ "$*" == *--no-build* ]] ; then
  BUILD=0
fi

if [[ "$*" == *--rebuild* ]] ; then
  NOSKIP=1
  make_commands=${make_commands}" -f"
fi

if [[ "$*" == *--no-x86_64* ]] ; then
  MAKE_64=0
fi

if [[ "$*" == *--no-i686* ]] ; then
  MAKE_32=0
fi

if [[ "$*" == *--update* ]] ; then
  UPDATE=1
fi

if [[ "$*" == *--repo-add* ]] ; then
  ADD_TO_REPO=1
fi

if [[ "x$CLEAN_BEFORE" != "x0" ]] ; then
  make_commands=${make_commands}" -C"
fi
  
if [[ "x$CLEAN_AFTER" != "x0" ]] ; then
  make_commands=${make_commands}" -c"
fi

#
# define action functions
#

function make_package () {
  makepkg ${make_commands} >> ${LOGFILE} 2>&1
}

function make_package_32 () {
  linux32 makepkg --config ${CONFIG32} ${make_commands} >> ${LOGFILE} 2>&1
}

function update_from_git () {
  git pull >> ${LOGFILE} 2>&1
}

function copy_to_repo (){
  arch=$1

  for j in *"${arch}.pkg.tar.xz" *any.tar.xz; do
    if [ -f $j ] ; then
      cp $j ${REPO_DIR}/${arch}/ >> ${LOGFILE} 2>&1
    fi
  done
}

function update_repo () {
  echo "updating repository"
  for arch in i686 x86_64; do
    repo-add ${REPO_DIR}/${arch}/archbio.db.tar.gz ${REPO_DIR}/${arch}/*.tar.xz >> ${LOGFILE} 2>&1
  done
}

function error_exit () {
  echo "ERROR: $1" 1>&2
  echo "See ${LOGFILE} for details"
  exit 1
}

function requires_rebuild () {
  local pkgbuild=$1

  local rebuild=0

  if [ -f $pkgbuild ] ; then
    # get list of filenames that will be produced
    local files=`${PKGBUILD_PARSER} PKGBUILD pkgfiles`
    for f in $files
    do
      if [ ! -f $f ] ; then
        rebuild=1
      fi
    done
  fi

  if [ "$rebuild" == "1" ] ; then
    return 0
  fi

  return 1
}

#
# start making packages
#

# clean the logfile
echo "" > ${LOGFILE}

if [[ "x$BUILD" != "x0" ]] ; then
  for i in [a-z]*;do

    if [ -d $i ]; then
      if [ -f $i/PKGBUILD ]; then
        cd $i;
#        echo "processing $i"
        echo -en `${PKGBUILD_PARSER} PKGBUILD info`
        # update from aur.archlinux.org git repo
        if [ -d .git ] ; then
          if [[ "x$UPDATE" != "x0" ]] ; then
            echo "updating git repo" >> ${LOGFILE}
            update_from_git || error_exit "Failed to pull from git repo"
          fi
        fi

        if requires_rebuild "PKGBUILD" || [ "x$NOSKIP" != "x0" ] ; then

          rm -f `${PKGBUILD_PARSER} PKGBUILD pkgfiles`

          # make 64bit/any package
          if [ "x$MAKE_64" != "x0" ] ; then
            echo "making 64bit package" >> ${LOGFILE}
            make_package || error_exit "Makepkg exited with error"
            if [ "x$ADD_TO_REPO" != "x0" ] ; then
              copy_to_repo "x86_64" || error_exit "Failed to copy packages to repository ${REPO_DIR}/x86_64"
            fi
          fi

          # make i686 package
          if [ "x$MAKE_32" != "x0" ] ; then
            echo "making 32bit package" >> ${LOGFILE}
            make_package_32 || error_exit "Makepkg exited with error, see logfile ${LOGFILE}"
            if [ "x$ADD_TO_REPO" != "x0" ] ; then
              copy_to_repo "i686" || error_exit "Failed to copy packages to repository ${REPO_DIR}/i686"
            fi
          fi

        fi

        cd ..
      fi
    fi
  done
fi

# update the repository database
if [ "x$ADD_TO_REPO" != "x0" ] ; then
  update_repo || error_exit "Failed to update repo"
fi

