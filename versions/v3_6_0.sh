
#Mobile
#Added at SmartDB Ver.3.6.0
proj=Mobile
if [ -f $BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki/$proj ]; then
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export MOBILE_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar
fi
