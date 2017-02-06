# java Build Script
A script to build Hibiki-SmartDB in one line

Usage:

    ssh username@svn.dev.dreamarts.co.jp
    su - root
    cd /root
    git clone https://stainless.dreamarts.co.jp/SmartDB/smartdb-builder.git
    chmod -R +x /root/smartdb-builder
    cd /root/smartdb-builder
    ./smartdb-builder.sh [command]
      Usage: smartdb-builder [command]
        Command:
            list  [option]             List remote avaliable branches or tags  
            build [option] [name]      Build modules from remote branches
            test  [option] [name]      Execute Junit Test for remote tags
        Option:
            tags                 List/Build/Test by remote tags
            branches             List/Build/Test by remote branches
    eg. 
    ## build master branch 
    ./smartdb-builder build branches master
    
    ## run junit test on master branch 
    ./smartdb-builder test branches master

    ## Download Url
    https://svn.dev.dreamarts.co.jp/builds/modules/HIBIKI-SmartDB/[branches type]/[name]/release-file


