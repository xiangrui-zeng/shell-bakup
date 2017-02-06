#!/bin/bash

#import all env
eval "`cat .base_dir`"
. $BUILD_BASE_DIR/lib/functions || {
  echo "Error sourcing functions."
  echo "Dependency failed: No functions libray found.";
  exit 1;
}

ANT_HOME=/opt/apache-ant-1.7.1

REPO=$1

VERSION=$2

VERSION_NAME=`generate_version_name`

# Our own variables
export LOG_DIR="log"
export MY_TARGETDIR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$MODULE

cd $BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki
export LAST_UPDATE_REV=`LC_ALL=C LANG=C git log -n 1 --pretty=format:"%H" $MODULE | cut -c1-7`;
if [ $MODULE = "jp.co.dreamarts.hibiki.smartdb" ]; then
  export LAST_CHANGED_DATE=`LC_ALL=C LANG=C git log -n 1 --pretty=format:%cd`;
else
  export LAST_CHANGED_DATE=`LC_ALL=C LANG=C git log -n 1 --pretty=format:%cd $MODULE`;
fi
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
    echo "build log: $SVN_URL_BUILDS/modules/HIBIKI-SmartDB/$REPO/$VERSION/$MODULE/$LOGFILENAME"
    echo ""
  }
  # cleanup
  [ ! $DEBUG ] && rm -rf $LOG_DIR
  
  #back to base dir
  cd $BUILD_BASE_DIR
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
  
  printb "Prepare for Building $MODULE" &&

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

  $ANT_HOME/bin/ant -Dbuild.jar="${MODULE}.jar" \
      -Dsvn.rev.no=$LAST_UPDATE_REV \
      -Dsvn.rev.date="$LAST_CHANGED_DATE" \
      -Dsvn.repos.path=$MODULE \
      -DTODAY=$TODAY \
      -Dhibiki.framework=$BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki/HIBIKI_v1_0 build 

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
  printb "Copy JAR to TARGETDIR... " &&
  cp -v ${MODULE}.jar $MY_TARGETDIR/${TARGET_NAME}.jar &&
  ln -sf $MY_TARGETDIR/${TARGET_NAME}.jar $MY_TARGETDIR/$TARGET_NAME_SHORT-latest.jar &&
  ln -sf $MY_TARGETDIR/${TARGET_NAME}.buildlog $MY_TARGETDIR/$TARGET_NAME_SHORT-latest.buildlog &&
  if [ -f dist.manifest.dat ]; then
    cat dist.manifest.dat | process_manifest $TARGET_NAME-dist &&
    zip -r $MY_TARGETDIR/$TARGET_NAME-dist.zip $TARGET_NAME-dist &&
    ln -sf $MY_TARGETDIR/${TARGET_NAME}-dist.zip $MY_TARGETDIR/$TARGET_NAME_SHORT-latest-dist.zip
  fi


  printb "Running JUnit tests..."

  #you have to export ENABLE_MODULE_JUNIT=true to execute junit
  if [ "$ENABLE_MODULE_JUNIT" ]; then

          # Additional JARS
          if [ "$JARS_JUNIT" ]; then
            IFS=':' 
            for jar in $JARS_JUNIT; do 
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


          $ANT_HOME/bin/ant -Dbuild.jar="${TARGET_NAME}.jar" \
              -Dsvn.rev.no=$LAST_UPDATE_REV \
              -Dsvn.repos.path=$MODULE \
              -DTODAY=$TODAY \
              -Dhibiki.framework=$BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki/HIBIKI_v1_0 junit 
          if [ $? -ne 0 ]; then echo "ant junit failed, abort."; exit 1; fi
  fi

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

exit $?
