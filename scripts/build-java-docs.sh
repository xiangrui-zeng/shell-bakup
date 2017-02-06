#!/bin/bash

##############################################################################
# 
# Script to build Java Doc.
# Copy from module-build.sh
# 
##############################################################################

#import all env
eval "`cat .base_dir`"
. $BUILD_BASE_DIR/lib/functions || {
  echo "Error sourcing functions."
  echo "Dependency failed: No functions libray found.";
  exit 1;
}

REPO=$1

VERSION=$2

MODULE=SmartdbAPI

VERSION_NAME=`generate_version_name`

# Our own variables
export LOG_DIR="log"
export MY_TARGETDIR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$MODULE

cd $BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki
export LAST_UPDATE_REV=`LC_ALL=C LANG=C git log -n 1 --pretty=format:"%H" $MODULE | cut -c1-7`;
export LAST_CHANGED_DATE=`LC_ALL=C LANG=C git log -n 1 --pretty=format:%cd $MODULE`;
cd $BUILD_BASE_DIR

on_exit() {
  echo "############################################# "
  echo "#                                            "
  echo "# Build Info.                                "
  echo "# SmarDB builder Version 0.1                 "
  echo "# Target Module :                            "
  echo "# $MODULE                                    "
  echo "# Last Commit Hash:                          "
  echo "# $LAST_UPDATE_REV                           "
  echo "# Last Upate Date:                           "
  echo "# $LAST_CHANGED_DATE                          "
  echo "#                                            "
  echo "############################################# "
  [ -f $BUILD_BASE_DIR/$LOG_DIR/build.log ] && {
    mkdir -p $MY_TARGETDIR &&
    LOGFILENAME=build.log
    if [ -f "$BUILD_BASE_DIR/$LOG_DIR"/output_jar_file_name ] ; then
       LOGFILENAME=`cat $BUILD_BASE_DIR/$LOG_DIR/output_jar_file_name`.buildlog
    fi
    mv -v "$LOG_DIR/build.log" "$MY_TARGETDIR/$LOGFILENAME"
    echo "build log: $SVN_URL_BUILDS/modules/HIBIKI-SmartDB/$VERSION/$REPO/$MODULE/$LOGFILENAME"
    echo ""
  }
  # cleanup
  [ ! $DEBUG ] && rm -rf $LOG_DIR
}

trap on_exit EXIT

# important: create and enter into WORKDIR before anything else; 
# because, for example, the logfile may be placed there.
mkdir -p $BUILD_BASE_DIR/$LOG_DIR &&
##############################################################################
# Everything from this point onwards gets logged.
##############################################################################
(
  date;
  printb "Starting module build: $MODULE" 

  cd $BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki

  if [ "$SERVLET_JAR" ]; then
    cp -v $SERVLET_JAR HIBIKI_v1_0/webapp/WEB-INF/lib/
  else
    # This was naughty.
    # cp `locate servlet.jar | tail -n1`  ../HIBIKI_v1_0/webapp/WEB-INF/lib/
    printb "Stealing servlet.jar from https://svn.dev.dreamarts.co.jp/svn/hibiki/Framework/tags/1_0_0/lib/ ..." &&
    svn cat https://svn.dev.dreamarts.co.jp/svn/hibiki/Framework/tags/1_0_0/lib/servlet.jar > HIBIKI_v1_0/webapp/WEB-INF/lib/servlet.jar
  fi &&

  # Optional Variables
  # Additional JARS
  if [ "$JARS" ]; then
    IFS=':' 
    for jar in $JARS; do 
      if [ -f "$jar" ] && jar tf $jar > /dev/null ; then
        # You're not kidding; this truly be a jar file
        # Copy it to our lib.
        echo "Including JAR: `basename $jar`..."
        cp -v $jar $BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki/HIBIKI_v1_0/webapp/WEB-INF/lib/
      else
        printb "ERROR: $jar is not a JAR file."
        exit 1;
      fi 
    done
    unset IFS
  fi &&
  
  printb "Prepare for Building Java Doc ($MODULE)" &&

  printb "NOTE: The requested REV was $REV; the latest revision for this module is $LAST_UPDATE_REV. Starting build..." &&
  printb "NOTE: The Last Changed Date of modules built by now is $LAST_CHANGED_DATE." &&
  cd $MODULE && 
  export TARGET_NAME_SHORT=$MODULE'-'$REPO'-'$VERSION_NAME &&
  export TARGET_NAME=$TARGET_NAME_SHORT'-'$LAST_UPDATE_REV'-'$TODAY &&
  echo $TARGET_NAME > $BUILD_BASE_DIR/$LOG_DIR/output_jar_file_name &&
  if [ "$WITH_SOURCES" = "yes" ] ; then
    printb "NOTE : WILL INCLUDE ALL SOURCES IN THIS JAR!"
    export ANT_ARGS="$ANT_ARGS -Dwith.sources=with.sources";
  fi

  ## check out failed?
  if [ $? -ne 0 ]; then
    echo "Failed to check out."
    exit 1
  fi

  $ANT_HOME/bin/ant \
      -Dsvn.rev.no=$LAST_UPDATE_REV \
      -Dsvn.rev.date="$LAST_CHANGED_DATE" \
      -Dsvn.repos.path=$MODULE \
      -Djsdoc.home=$JSDOC_HOME \
      -DTODAY=$TODAY \
      -Dhibiki.framework=$BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki/HIBIKI_v1_0 javadoc jsdoc 

  ## check out failed?
  if [ $? -ne 0 ]; then
    echo "ant build failed."
    exit 1
  fi

  mkdir -p $MY_TARGETDIR &&
  printb "Cleaning up older release files..:" &&
  find $MY_TARGETDIR -name '*' -type f -daystart -mtime +3 | sort -r | while read file
  do
    echo "Deleting $file..."
    rm -rf $file ;
  done &&
  printb "Zip docs to $MY_TARGETDIR/... " &&
  zip -r ${TARGET_NAME}-docs.zip javadoc jsdoc &&
  cp -v ${TARGET_NAME}-docs.zip $MY_TARGETDIR/${TARGET_NAME}-docs.zip
  ln -sf $MY_TARGETDIR/${TARGET_NAME}-docs.zip $MY_TARGETDIR/$TARGET_NAME_SHORT-docs-latest.zip &&
  ln -sf $MY_TARGETDIR/${TARGET_NAME}.docslog $MY_TARGETDIR/$TARGET_NAME_SHORT-latest.docslog &&

printb "Build complete."

# Optional Variables
  # delete JARS
  if [ "$JARS" ]; then
    IFS=':' 
    for jar in $JARS; do 
      if [ -f "$jar" ] && jar tf $jar > /dev/null ; then
        # You're not kidding; this truly be a jar file
        # Copy it to our lib.
        echo "Deleting JAR: `basename $jar`...";
        fname="`basename $jar`"
        cd $BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki/HIBIKI_v1_0/webapp/WEB-INF/lib/
        rm -rf $fname
        cd -
      else
        printb "ERROR: $jar is not a JAR file."
        exit 1;
      fi 
    done
    unset IFS
  fi
 
  
) > $BUILD_BASE_DIR/$LOG_DIR/build.log 2>&1

cd $BUILD_BASE_DIR

exit $?
