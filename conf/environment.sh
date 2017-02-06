#build env
export BUILD_WORKDIR=.hibiki-smartdb
export TARGETDIR=/var/www/builds/
export RELEASEDIR=/var/www/releases/
export MODULE_TARGETDIR=$TARGETDIR/modules/
export JAVA_HOME=/opt/jdk1.7
export PATH=$JAVA_HOME/bin:$PATH
export SERVLET_JAR=/opt/servletJar/servlet-api-3.0.jar
export ANT_HOME=/opt/apache-ant-1.7.1
export JSDOC_HOME=/opt/jsdoc_toolkit-2.3.2/
export LANG="ja_JP.utf-8"

# Stuff for jenkins
export SVN_URL_BUILDS=https://svn.dev.dreamarts.co.jp/builds
export SVN_URL_RELEASES=https://svn.dev.dreamarts.co.jp/releases
export SVN_URL_DOCS=https://svn.dev.dreamarts.co.jp/docs

#Junit test env
export JUNITDB=Oracle
