#!/bin/bash
#FW Build Script

#import all env
eval "`cat .base_dir`"
. $BUILD_BASE_DIR/lib/functions || {
  echo "Error sourcing functions."
  echo "Dependency failed: No functions libray found.";
  exit 1;
}

REPO=$1

VERSION=$2

export LOG_DIR="log"

export HIBIKI_MODULE="HIBIKI_v1_0"

export MY_TARGETDIR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$HIBIKI_MODULE

printb "HIBIKI Framework v1.0 Build: $TODAY";

cd $BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki

export LAST_UPDATE_REV=`LC_ALL=C LANG=C git log -n 1 --pretty=format:"%H" $HIBIKI_MODULE | cut -c1-7`;

export LAST_CHANGED_DATE=`LC_ALL=C LANG=C git log -n 1 --pretty=format:%cd $HIBIKI_MODULE`;

on_exit() {
  echo "############################################# "
  echo "#                                            "
  echo "# Build Info.                                "
  echo "# SmarDB builder Version 0.1                 "
  echo "# Target Module :                            "
  echo "# $HIBIKI_MODULE                                    "
  echo "# Last Commit Hash:                          "
  echo "# $LAST_UPDATE_REV                           "
  echo "# Last Upate Date:                           "
  echo "# $LAST_CHANGED_DATE                          "
  echo "#                                            "
  echo "############################################# "
  [ -f $BUILD_BASE_DIR/$LOG_DIR/build.log ] && {
    mkdir -p $MY_TARGETDIR &&
    LOGFILENAME=hibiki-war-$LAST_UPDATE_REV-$TODAY.buildlog
    mv -v "$LOG_DIR/build.log" "$MY_TARGETDIR/$LOGFILENAME"
    echo "build log: $SVN_URL_BUILDS/modules/HIBIKI-SmartDB/$REPO/$VERSION/$HIBIKI_MODULE/$LOGFILENAME"
    echo ""
  }
  # cleanup
  [ ! $DEBUG ] && rm -rf $LOG_DIR
}

trap on_exit EXIT

mkdir -p $BUILD_BASE_DIR/$LOG_DIR &&
(
printb "NOTE: The latest commit for this HIBIKI_v1_0 is $LAST_UPDATE_REV. Starting build..." &&

#
# struts-config.xml
polite_sed ' 
        /__begin_debug__/, /__end_debug__/d
' HIBIKI_v1_0/webapp/WEB-INF/struts-config.xml &&
#
# velocity.properties
polite_sed '
        /^\s*webapp.resource.loader.cache/s/false/true/;        # Enable the Velocity cache (webapp loader).
        /^\s*class.resource.loader.cache/s/false/true/;         # Enable the Velocity cache (classpath loader).
        /^\s*velocimacro.library.autoreload/s/true/false/;      # Disable auto-reloading in production.
' HIBIKI_v1_0/webapp/WEB-INF/velocity.properties &&
#
# log4j.xml
polite_sed  '
        /__begin_devel_only__/s/-->//;                          # Block-comment the devel-only config.
        /__end_devel_only__/s/<!--//;
        /__begin_production_only__/ {                           # Block-uncomment the production-only
                /-->/ ! {                                       # config. 
                        s/$/-->/; 
                } 
        }
        /\(__end_production_only__\)/ { 
                /<!--/ ! { 
                        s/__end/<!-- __end/; 
                } 
        }
' HIBIKI_v1_0/src/log4j.xml &&
#
# web.xml
polite_sed '
        /__begin_debug__/, /__end_debug__/d
' HIBIKI_v1_0/webapp/WEB-INF/web.xml &&
# Done with text replacements.

cd HIBIKI_v1_0 &&

printb "Building hibiki.war now...." &&
ant -Dsvn.rev.no=$LAST_UPDATE_REV jar
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ant jar failed: $EXIT_CODE"
fi

) > $BUILD_BASE_DIR/$LOG_DIR/build.log 2>&1

cd $BUILD_BASE_DIR

exit $EXIT_CODE
