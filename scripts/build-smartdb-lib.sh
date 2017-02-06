#!/bin/sh
eval "`cat .base_dir`"
. $BUILD_BASE_DIR/lib/functions || {
  echo "Error sourcing functions."
  echo "Dependency failed: No functions libray found.";
  exit 1;
}

unset LANG

REPO=$1

VERSION=$2

export WORK_DIR=$BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki
export MY_TARGETDIR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$MODULE

if [ -z "$BASEDIR" ]; then
        BASEDIR=SmartDB/$1
fi

#modules=`svn ls -r$REV $HIBIKI_REPOS/$BASEDIR`
modules="jp.co.dreamarts.hibiki.workflow jp.co.dreamarts.hibiki.quartz jp.co.dreamarts.hibiki.smartdb.soap jp.co.dreamarts.hibiki.smartdb.tool"
SMARTDB_ALL_LIB_DIR=$WORK_DIR/smartdb_all_lib
SMARTDB_ALL_LIB_LIST=$WORK_DIR/smartdb_all_lib.lst
rm -f $SMARTDB_ALL_LIB_LIST
rm -fr $SMARTDB_ALL_LIB_DIR
mkdir -p $SMARTDB_ALL_LIB_DIR
#
# create SmartDB_lib.lst for md5
#
#date=""
cd $BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki/$MODULE
for module in $modules; do
        jars=`ls -1 $WORK_DIR/$module/lib | egrep jar$`
        for jar in $jars; do
                # get one jar file svn revision
                target=$WORK_DIR/$module/lib/$jar
                rev=`LC_ALL=C LANG=C git log -1 $target | sed -n '1,1p' | awk -F 'commit ' '{print $2}' | cut -c1-7`;
                #date=`LC_ALL=C LANG=C git log -1 $target | sed -n '1,1p' | awk -F 'Date:  ' '{print $2}'`;
                # add to package info list
                echo "${rev} ${jar}" >> $SMARTDB_ALL_LIB_LIST
                # keep latest revision number
              #  if [ $lastChangedDate -lt $date ]; then
                        lastChangedRev=$rev
              #  fi
                # copy jar file
                cp $target $SMARTDB_ALL_LIB_DIR/$jar
        done
done

#
# ant task <smartdb_lib> will rejar all jar files under $SMARTDB_ALL_LIB_DIR, into ${TARGET_NAME}.jar
#

TARGET_NAME="SmartDB_LIB-${lastChangedRev}-${TODAY}"
TARGET_NAME_SHORT="SmartDB_LIB"
ant -Dsmartdb_lib.jar="SmartDB_LIB.jar" \
        -Dsmartdb_lib.jar.dir=$SMARTDB_ALL_LIB_DIR \
        -Dsvn.rev.no=$lastChangedRev \
        -Dsvn.repos.path=$HIBIKI_REPOS/$BASEDIR \
        -DTODAY=$TODAY smartdb_lib
if [ $? -ne 0 ]; then echo "ant smartdb_lib failed, abort."; exit $?; fi

cp -p  SmartDB_LIB.jar $MY_TARGETDIR/${TARGET_NAME}.jar
ln -sf $MY_TARGETDIR/${TARGET_NAME}.jar $MY_TARGETDIR/$TARGET_NAME_SHORT-latest.jar
#
# cleanup
#
rm -f $SMARTDB_ALL_LIB_LIST
rm -fr $SMARTDB_ALL_LIB_DIR
cd $BUILD_BASE_DIR

exit $?
