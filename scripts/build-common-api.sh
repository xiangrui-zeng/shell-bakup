#!/bin/sh

#######################################################################
## 
##   HibikiCommonAPI build script
## 
## 
#######################################################################

#import all env
eval "`cat .base_dir`"
. $BUILD_BASE_DIR/lib/functions || {
  echo "Error sourcing functions."
  echo "Dependency failed: No functions libray found.";
  exit 1;
}

#$1
REPO=$1

VERSION=$2

VERSION_NAME=`generate_version_name`

echo "Start building HibikiCommonAPI ..."

# Already built FRAMEWORK, just for library reference, any release will be fine.
export FRAMEWORK_WAR=$RELEASEDIR/HIBIKI/1_1_1/hibiki.war

# build HibikiCommonAPI
proj=HibikiCommonAPI_StandaloneSupport
MODULE=$proj ./scripts/module-build.sh $REPO $VERSION
if [ $? -ne 0 ]; then echo "HibikiCommonAPI_StandaloneSupport build failed, abort."; exit $?; fi
export SUPPORT_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

proj=HibikiCommonAPI
JARS="$SUPPORT_JAR" MODULE=$proj ./scripts/module-build.sh $REPO $VERSION
if [ $? -ne 0 ]; then echo "HibikiCommonAPI build failed, abort."; exit $?; fi

exit $?
