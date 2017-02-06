#!/bin/sh

#######################################################################
## 
##   SmartDB build script.
## 
#######################################################################

#import all env
eval "`cat .base_dir`"
. $BUILD_BASE_DIR/lib/functions || {
  echo "Error sourcing functions."
  echo "Dependency failed: No functions libray found.";
  exit 1;
}

# Check parameters, determine release definition
REPO=$1

VERSION=$2

VERSION_NAME=`generate_version_name`

MODULE_BUILD="./scripts/module-build.sh  $REPO $VERSION"

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


echo "Start building/HIBIKI-SmartDB/$REPO/$VERSION against Framework $FRAMEWORK_RELEASE_TAG..."

# Common Libraries : Quartz libraries
QUARTZ_LIB=$BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki/jp.co.dreamarts.hibiki.quartz/lib
export QUARTZ_JAR="$QUARTZ_LIB/quartz-2.2.3.jar:$QUARTZ_LIB/slf4j-api-1.7.7.jar:$QUARTZ_LIB/slf4j-log4j12-1.7.7.jar"

# Common Libraries : Hibernate libraries
HIBERNATE_LIB=$BUILD_BASE_DIR/$BUILD_WORKDIR/hibiki/jp.co.dreamarts.hibiki.workflow/lib
export HIBERNATE_JAR="$HIBERNATE_LIB/hibernate3.jar:$HIBERNATE_LIB/ejb3-persistence.jar:$HIBERNATE_LIB/hibernate-commons-annotations.jar:$HIBERNATE_LIB/antlr-2.7.6.jar:$HIBERNATE_LIB/hibernate-annotations.jar:$HIBERNATE_LIB/jta.jar"

# SMARTDB_API
proj=SmartdbAPI
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JSDOC_HOME=/opt/jsdoc_toolkit-2.3.2-jdk5/ JARS="$COMMON_API_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export SMARTDB_API_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# HIBIKI_QUARTZ
proj=jp.co.dreamarts.hibiki.quartz
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export HIBIKI_QUARTZ_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# GenLink
proj=jp.co.dreamarts.hibiki.genlink
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export GENLINK_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# SMARTDB
proj=SmartDB
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$QUARTZ_JAR:$HIBIKI_QUARTZ_JAR:$GENLINK_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export SMARTDB_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Reuse button
proj=jp.co.dreamarts.hibiki.smartdb.button.reuse
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export BUTTON_REUSE_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Item style
proj=jp.co.dreamarts.hibiki.smartdb.itemstyle
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
#export ITEM_STYLE_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Document Cache List Definition Page 
proj=jp.co.dreamarts.hibiki.smartdb.dlcdefinition
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi

# LuceneOptimize Command
proj=jp.co.dreamarts.hibiki.smartdb.luceneoptimize
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi


# Toolbox
proj=jp.co.dreamarts.hibiki.toolbox
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export TOOLBOX_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Category
proj=jp.co.dreamarts.hibiki.smartdb.category
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_API_JAR:$SMARTDB_JAR:$TOOLBOX_JAR:$COMMON_API_JAR" MODULE=$proj  $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export CATEGORY_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# EditView
proj=jp.co.dreamarts.hibiki.smartdb.editview
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_API_JAR:$SMARTDB_JAR:$CATEGORY_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export EDITVIEW_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# EditFilter
proj=jp.co.dreamarts.hibiki.smartdb.editfilter
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$CATEGORY_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi

# RichText
proj=jp.co.dreamarts.hibiki.smartdb.richtext
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export RICHTEXT_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# DocumentList
proj=jp.co.dreamarts.hibiki.smartdb.documentlist
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$TOOLBOX_JAR:$CATEGORY_JAR:$EDITVIEW_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export DOCUMENTLIST_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# ListType
proj=jp.co.dreamarts.hibiki.smartdb.item.listtype
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$SMARTDB_API_JAR:$RICHTEXT_JAR:$CATEGORY_JAR:$COMMON_API_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export LISTTYPE_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# MASTER
proj=jp.co.dreamarts.hibiki.smartdb.master
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export MASTER_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# EditForm
proj=jp.co.dreamarts.hibiki.smartdb.editform
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$LISTTYPE_JAR:$SMARTDB_JAR:$TOOLBOX_JAR:$EDITVIEW_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi


# Document History
proj=jp.co.dreamarts.hibiki.smartdb.history
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$TOOLBOX_JAR:$EDITVIEW_JAR:$DOCUMENTLIST_JAR:$LISTTYPE_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export HISTORY_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Subform
proj=jp.co.dreamarts.hibiki.smartdb.subform
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$BUTTON_REUSE_JAR:$GENLINK_JAR:$SMARTDB_JAR:$HISTORY_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export SUBFORM_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Background
proj=jp.co.dreamarts.hibiki.smartdb.background
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$QUARTZ_JAR:$HIBIKI_QUARTZ_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export BACKGROUND_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# CSV
proj=jp.co.dreamarts.hibiki.smartdb.csv
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$SMARTDB_API_JAR:$LISTTYPE_JAR:$SUBFORM_JAR:$DOCUMENTLIST_JAR:$HISTORY_JAR:$EDITVIEW_JAR:$GENLINK_JAR:$BACKGROUND_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export CSV_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Workflow
proj=jp.co.dreamarts.hibiki.workflow
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$TOOLBOX_JAR:$HISTORY_JAR:$CATEGORY_JAR:$DOCUMENTLIST_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export WORKFLOW_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Sanction
proj=jp.co.dreamarts.hibiki.smartdb.sanction
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$TOOLBOX_JAR:$HISTORY_JAR:$CATEGORY_JAR:$DOCUMENTLIST_JAR:$WORKFLOW_JAR:$HIBERNATE_JAR"  MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export SANCTION_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Statistics
proj=jp.co.dreamarts.hibiki.smartdb.stats
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi

# Template Item
proj=jp.co.dreamarts.hibiki.smartdb.item.template
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi

# IMP
proj=jp.co.dreamarts.hibiki.imp
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$TOOLBOX_JAR:$RICHTEXT_JAR:$WORKFLOW_JAR:$HIBERNATE_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export IMP_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# CommonItem
proj=jp.co.dreamarts.hibiki.smartdb.commonitem
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$SMARTDB_API_JAR:$COMMON_API_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export COMMONITEM_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# ProcessList
proj=jp.co.dreamarts.hibiki.smartdb.processlist
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$TOOLBOX_JAR:$RICHTEXT_JAR:$WORKFLOW_JAR:$HIBERNATE_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export PROCESSLIST_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# ItemControl
proj=jp.co.dreamarts.hibiki.smartdb.itemcontrol
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$SUBFORM_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export ITEMCONTROL_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# DocumentControl
proj=jp.co.dreamarts.hibiki.smartdb.documentcontrol
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$SMARTDB_API_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export DOCUMENTCONTROL_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Bulk Operations
proj=jp.co.dreamarts.hibiki.smartdb.operations
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$TOOLBOX_JAR:$RICHTEXT_JAR:$DOCUMENTLIST_JAR:$CATEGORY_JAR:$EDITVIEW_JAR:$LISTTYPE_JAR:$WORKFLOW_JAR:$HIBERNATE_JAR:$BACKGROUND_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export OPERATIONS_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# SOAP Server
proj=jp.co.dreamarts.hibiki.smartdb.soap
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$TOOLBOX_JAR:$CATEGORY_JAR:$WORKFLOW_JAR:$HIBERNATE_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export SOAP_SERVER_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# RESTful API
proj=RESTAPI
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$HISTORY_JAR:$SANCTION_JAR:$TOOLBOX_JAR:$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$EDITVIEW_JAR:$CATEGORY_JAR:$QUARTZ_JAR:$HIBIKI_QUARTZ_JAR:$PROCESSLIST_JAR:$WORKFLOW_JAR:$HIBERNATE_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export REST_API_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Standalone
proj=jp.co.dreamarts.hibiki.smartdb.standalone
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi

# AjaxAPI @since 3.0
proj=jp.co.dreamarts.hibiki.smartdb.ajaxapi
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_API_JAR:$SMARTDB_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi

# jp.co.dreamarts.hibiki.account.synchronize
proj=jp.co.dreamarts.hibiki.account.synchronize
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$QUARTZ_JAR:$HIBIKI_QUARTZ_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export ACCOUNT_SYNC_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# SmartDB command-line tool
proj=jp.co.dreamarts.hibiki.smartdb.tool
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$WORKFLOW_JAR:$SMARTDB_API_JAR:$COMMON_API_JAR:$ACCOUNT_SYNC_JAR:$QUARTZ_JAR:$HIBIKI_QUARTZ_JAR" MODULE=$proj $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export TOOL_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Luxor
proj=jp.co.dreamarts.hibiki.smartdb.luxor
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$COMMON_API_JAR:$SMARTDB_API_JAR:$SMARTDB_JAR:$CATEGORY_JAR:$LISTTYPE_JAR:$IMP_JAR:$WORKFLOW_JAR:$HIBERNATE_JAR:$TOOL_JAR:$SUBFORM_JAR:$GENLINK_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export LUXOR_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Docexport
proj=jp.co.dreamarts.hibiki.smartdb.docexport
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$TOOLBOX_JAR:$CATEGORY_JAR:$LISTTYPE_JAR:$SMARTDB_API_JAR:$ITEMCONTROL_JAR:$WORKFLOW_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export DOCEXPORT_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Scheduledjob
proj=jp.co.dreamarts.hibiki.smartdb.scheduledjob
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
JARS="$SMARTDB_JAR:$CATEGORY_JAR:$SMARTDB_API_JAR:$HIBIKI_QUARTZ_JAR:$COMMON_API_JAR:$OPERATIONS_JAR:$QUARTZ_JAR" MODULE=$proj   $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
export SCHEDULED_JOB_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

# Mobile
#proj=Mobile
#rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
#JARS="$SMARTDB_JAR" MODULE=$proj   $MODULE_BUILD
#if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi
#export MOBILE_JAR=$MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.jar

eval "`cat $BUILD_BASE_DIR/versions/*.sh`"

# SMARTDB_CORE (combine modules)
proj=jp.co.dreamarts.hibiki.smartdb
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
MODULE=$proj  $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi

# SMARTDB_LIB 
MODULE=$proj  ./scripts/build-smartdb-lib.sh  $REPO $VERSION
if [ $? -ne 0 ]; then echo "smartdb_lib build failed, abort."; exit 1; fi

# Profiling module
proj=jp.co.dreamarts.hibiki.profile
rm -f $MODULE_TARGETDIR/HIBIKI-SmartDB/$REPO/$VERSION/$proj/$proj-$REPO-$VERSION_NAME-latest.*
MODULE=$proj  $MODULE_BUILD
if [ $? -ne 0 ]; then echo "Module build failed, abort."; exit 1; fi

exit $?
