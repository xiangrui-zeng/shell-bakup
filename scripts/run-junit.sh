#!/bin/sh

#######################################################################
## 
##   junit build script, using existing Framework.
## 
#######################################################################

#import all env
eval "`cat .base_dir`"
. $BUILD_BASE_DIR/lib/functions || {
  echo "Error sourcing functions."
  echo "Dependency failed: No functions libray found.";
  exit 1;
}

export proj="junit.SmartDB"
export ENABLE_MODULE_JUNIT=1

#export DEBUG=1

if [ $JUNITDB = "Oracle" ]; then 
  # For Oracle
  export TARGET_DB=oracle
  export DB_URL=jdbc:oracle:thin:@localhost:1521:isdb
  export DBA_USER=hibiki_admin
  export DBA_PASS=hibiki_admin
elif [ $JUNITDB = "MySQL" ]; then
  # For MySQL
  export TARGET_DB=mysql
  export DB_URL=jdbc:mysql://localhost
  export DBA_USER=dbadmin
  export DBA_PASS=dbadmin
else
  echo "junit.SmartDB build failed, abort."; exit 1;
fi

MODULE_BUILD="./scripts/module-build.sh $1 $2"

# Check parameters, determine release definition
REPO=$1

VERSION=$2

VERSION_NAME=`generate_version_name`

export FRAMEWORK_WAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/HIBIKI_v1_0/hibiki.war

if [ ! -f $FRAMEWORK_WAR ]; then
        echo  $FRAMEWORK_WAR 
        echo "Framework \"$REPO/$VERSION\" does not existed, abort."
        exit -1
fi

export COMMON_API_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/HibikiCommonAPI/hibiki_common_api.jar
if [ ! -f $COMMON_API_JAR ]; then
        echo "HibikiCommonAPI \"$REPO/$VERSION\" does not existed, abort."
        exit -1
fi

echo "Start building/HIBIKI-SmartDB/$REPO/$VERSION/junit.SmartDB"

# pre-built libraries
SMARTDB_API_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/SmartdbAPI/SmartdbAPI-$REPO-$VERSION_NAME-latest.jar
SMARTDB_ALL_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/jp.co.dreamarts.hibiki.smartdb/jp.co.dreamarts.hibiki.smartdb-$REPO-$VERSION_NAME-latest.jar
SMARTDB_LIB=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/jp.co.dreamarts.hibiki.smartdb//SmartDB_LIB-latest.jar

JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_ALL_JAR:$SMARTDB_LIB" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "junit.SmartDB build failed, abort."; exit 1; fi

exit $?
