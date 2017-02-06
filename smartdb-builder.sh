#!/bin/sh

helpMSG() {
  echo ""
  echo "Usage: smartdb-builder [command] [option]"
  echo ""
  echo "Command:"
  echo ""
  echo "list  [option]             List remote avaliable branches or tags"  
  echo "build [option] [name]      Build modules from remote branches"
  echo "test  [option] [name]      Execute Junit Test for remote tags"
  echo ""
  echo "Option:"
  echo "tags                       List/Build/Test by remote tags"
  echo "branches                   List/Build/Test by remote branches"
  exit 1;
}

listBranches() {
  echo "Branches List:"
  git ls-remote https://stainless.dreamarts.co.jp/SmartDB/HibikiSmartDB-Beta.git | grep heads | awk -F 'refs/heads/' '{print $2}'
}

listTags() {
  echo "Tags List:"
  git ls-remote --tags https://stainless.dreamarts.co.jp/SmartDB/HibikiSmartDB-Beta.git | awk -F 'refs/tags/' '{print $2}'
}

listREPO() {
   listBranches
   echo ""
   listTags
}

if [ $# -lt 1 ]; then
   helpMSG
elif [ $# -eq 1 -a "$1" = "list" ]; then
  listREPO
  exit 1;
elif [ $# -eq 1 -a "$1" != "help" ]; then
  helpMSG
elif [ $# -eq 2 -a "$1" = "list" -a "$2" = "branches" ]; then
  listBranches
  exit 1;
elif [ $# -eq 2 -a "$1" = "list" -a "$2" = "tags" ]; then
  listTags
  exit 1;
elif [ $# -eq 3 -a "$1" = "build" -a "$2" = "branches" ]; then
   #do something in below
   echo "" 
elif [ $# -eq 3 -a "$1" = "build" -a  "$2" = "tags" ]; then
  #do something in below
  echo ""
elif [ $# -eq 3 -a "$1" = "test" -a  "$2" = "branches" ]; then
  #do something in below
  echo ""
elif [ $# -eq 3 -a "$1" = "test" -a  "$2" = "tags" ]; then
  #do something in below
  echo ""
else
  helpMSG

fi

echo "########################################################### "
echo "#                                                          "
echo "# SmartDB Module Builder.                                  "
echo "# Version 0.1                                              "
echo "# Repository:                                              "
echo "# https://stainless.dreamarts.co.jp/SmartDB/smartdb-builder.git  "
echo "#                                                          "
echo "########################################################### "

#build info
REPO=$2

VERSION=$3

#build base dir
getBaseDir() {
  oldwd=`pwd`
  rw=`dirname $0`
  cd $rw
  export BUILD_BASE_DIR=`pwd`
  echo "export BUILD_BASE_DIR=`pwd`" > .base_dir
}

getBaseDir

. $BUILD_BASE_DIR/lib/functions || {
  echo "Error sourcing functions."
  echo "Dependency failed: No functions libray found.";
  exit 1;
}

VERSION_NAME=`generate_version_name`

# svn host
SVN_HOST=https://svn.dev.dreamarts.co.jp

# git repo
GIT_HOST=https://stainless.dreamarts.co.jp/SmartDB/HibikiSmartDB-Beta.git

# create work directroy and make lock
if [ -f "$BUILD_WORKDIR"/lock ] ; then
  LOCKED_PID=`head -n1 "$BUILD_WORKDIR"/lock`
  if ps $LOCKED_PID > /dev/null; then
    # running process is still around.
    cat<<MSG
The build area $BUILD_WORKDIR is locked! 
Maybe another instance of a build script is already running?
MSG
    ps uw $LOCKED_PID
    cat<<MSG
Please wait until the running build process has completed.
MSG
    exit 1;
  fi
  # The process that made this lock is not alive anymore.
fi

mkdir -p $TARGETDIR

echo "build log: $SVN_URL_BUILDS/latest-build.log"
(

LABEL='hibiki'; # default label
EXIT_CODE=0

rm -rf $BUILD_WORKDIR;
mkdir -p $BUILD_WORKDIR;
#cd $BUILD_WORKDIR;
# Make a lock for ourself
echo $$ > lock;
)

# clone hole smartdb project 
 echo "git clone ${GIT_HOST} hibiki .."

#clone from branches
if [ "$2" = "branches" ] ; then 
  git clone -b $3 ${GIT_HOST} $BUILD_WORKDIR/hibiki || {
    printb "Checkout failed."
    exit 1
  }
elif [ "$2" = "tags" ]; then
  #statements
  git clone ${GIT_HOST} $BUILD_WORKDIR/hibiki || {
    printb "Checkout failed."
    exit 1
  }
  cd $BUILD_WORKDIR/hibiki
  git checkout $2/$3
  cd $BUILD_BASE_DIR
else
  printb "Checkout failed."
  exit 1
fi  

junitTest() {
  # run smartdb junit test
  echo "Execute Junit Test $REPO $VERSION..."

  echo "Prepare FrameWork For Junit..."
  ./scripts/build-framework.sh  $REPO $VERSION
  if [ $? -ne 0 ]; then echo "FrameWork build failed,Cant not test. abort."; exit 1; fi

  ./scripts/run-junit.sh $REPO $VERSION
  if [ $? -ne 0 ]; then echo "Junit Test failed, abort."; exit 1; fi
  rm -rf $BUILD_WORKDIR

  echo ""
  echo ""
  echo ""
  echo    " ########################################################################################################################## "
  echo    " #                                                                                                                         "
  echo    " # Junit test already completed "
  echo    " #                                                                                                                         "
  echo    " # For information on the log files, see $SVN_HOST/builds/modules/HIBIKI-SmartDB/$REPO/$VERSION/junit.SmartDB/.       "
  echo    " #                                                                                                                         "
  echo    " # Thank you !"
  echo    " #                                                                                                                         "
  echo    " ########################################################################################################################## "

  exit $?;
}

if [ "$1" = "test" ]; then
  junitTest
fi

# FW
echo "Building FrameWork $REPO $VERSION..."
./scripts/build-framework.sh  $REPO $VERSION
if [ $? -ne 0 ]; then echo "FW build failed, abort."; exit 1; fi
mkdir -p $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/HIBIKI_v1_0
echo "cp -p ./$BUILD_WORKDIR/hibiki/HIBIKI_v1_0/hibiki.war $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/hibiki.war..."
cp -p ./$BUILD_WORKDIR/hibiki/HIBIKI_v1_0/hibiki.war $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/HIBIKI_v1_0/hibiki.war


# HibikiCommonAPI
export COMMONAPI_DIR=$TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/HibikiCommonAPI
echo "Building HibikiCommonAPI $REPO $VERSION"
./scripts/build-common-api.sh $REPO $VERSION
if [ $? -ne 0 ]; then echo "HibikiCommonAPI build failed, abort."; exit 1; fi
mkdir -p $COMMONAPI_DIR
cp $COMMONAPI_DIR/HibikiCommonAPI-$REPO-$VERSION_NAME-latest.jar $COMMONAPI_DIR/hibiki_common_api.jar

# SDB
echo "Building SmartDB SubModule $REPO $VERSION..."
./scripts/build-smartdb.sh $REPO $VERSION
if [ $? -ne 0 ]; then echo "SmartDB SubModule build failed, abort."; exit 1; fi

# JavaDoc & JSDoc
echo "Building SmartDB Java Doc & Js Doc $REPO $VERSION..."
./scripts/build-java-docs.sh $REPO $VERSION

# Distribute document file to trac wiki
 
 rm -rf $BUILD_WORKDIR/javadoc_$VERSION_NAME
 mkdir -p $BUILD_WORKDIR/javadoc_$VERSION_NAME
 unzip -q $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/SmartdbAPI/SmartdbAPI-$REPO-$VERSION_NAME-docs-latest.zip -d $BUILD_WORKDIR/javadoc_$VERSION_NAME
 rm -rf /var/www/docs/SmartdbAPI/javadoc_$VERSION_NAME
 mv $BUILD_WORKDIR/javadoc_$VERSION_NAME/javadoc /var/www/docs/SmartdbAPI/javadoc_$VERSION_NAME
 rm -rf /var/www/docs/SmartdbAPI/jsdoc_$VERSION_NAME
 mv $BUILD_WORKDIR/javadoc_$VERSION_NAME/jsdoc /var/www/docs/SmartdbAPI/jsdoc_$VERSION_NAME
 rmdir $BUILD_WORKDIR/javadoc_$VERSION_NAME
 
 echo "Distribute document file to trac wiki : "
 echo "/var/www/docs/SmartdbAPI/javadoc_$VERSION_NAME"
 echo "/var/www/docs/SmartdbAPI/jsdoc_$VERSION_NAME"

#clean work dir
rm -rf $BUILD_WORKDIR

# move builded modules to release dir
rm -rf $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/release-file
mkdir -p $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/release-file

ln -sf $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/HIBIKI_v1_0/hibiki.war $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/release-file/hibiki.war

ln -sf $COMMONAPI_DIR/hibiki_common_api.jar $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/release-file/HIBIKI_Common_API_$VERSION_NAME.jar

ln -sf $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/jp.co.dreamarts.hibiki.smartdb/jp.co.dreamarts.hibiki.smartdb-$REPO-$VERSION_NAME-latest.jar $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/release-file/HIBIKI_SmartDB_CORE_$VERSION_NAME.jar

ln -sf $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/jp.co.dreamarts.hibiki.smartdb/SmartDB_LIB-latest.jar $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/release-file/HIBIKI_SmartDB_LIB_$VERSION_NAME.jar

ln -sf $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/SmartdbAPI/SmartdbAPI-$REPO-$VERSION_NAME-latest.jar $TARGETDIR/modules/HIBIKI-SmartDB/$REPO/$VERSION/release-file/HIBIKI_SmartdbAPI_$VERSION_NAME.jar


##download url
echo ""
echo ""
echo ""
echo    " ########################################################################################################################## "
echo    " #                                                                                                                         "
echo    " # Thanks for using SmartDB Builder.                                                                                       "
echo    " #                                                                                                                         "
echo    " # All build tasks was completed.                                                                                          "
echo    " #                                                                                                                         "
echo    " # Please download from the link below :                                                                                   "
echo    " #                                                                                                                         "
echo    " # $SVN_HOST/builds/modules/HIBIKI-SmartDB/$REPO/$VERSION/release-file                                       "
echo    " #                                                                                                                         "
echo    " ########################################################################################################################## "


