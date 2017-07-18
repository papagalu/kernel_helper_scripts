#!/usr/bin/env bash
# Copyright 2017 Cloudbase Solutions Srl
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

URL=""
FOLDER="debs"
TAR_DIRECTORY=""
CLEAN=false
CCACHE=true
REVISION="0.1.papagalu"
BASEDIR=`dirname $0`
JOBS="32"

function pushd() {
    command pushd "$@" > /dev/null
}

function popd() {
    command popd "$@" > /dev/null
}

function install_deps() {
    printf "\nInstalling dependencies.\n\n"
    sudo apt-get update
    sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc ccache kernel-package -y
    sudo sed -i -e "s/j1/j$JOBS/g" /usr/share/kernel-package/ruleset/targets/common.mk
    if [ $CCACHE = true ]
    then
        PATH=/usr/lib/ccache:$PATH
    fi
}

function download() {
    printf "\nStarting download from $URL\n\n"
    wget -nc $URL
    if [ $? -ne 0 ]
    then
        printf "\nDownload failed\nPossible bad URL: %s\n\n" $URL
        clean
    exit 2
    fi
}

function extract() {
    printf "\nExtracting tarball\n"
    TAR_DIRECTORY=`tar tzf *.tar.gz | head -1 | cut -f1 -d"/"`
    tar -xz -f *.tar.gz --no-overwrite-dir
    pushd $TAR_DIRECTORY
}

function prepare() {
    printf "\nPreparing for compiling the kernel\n\n"
    make olddefconfig
    touch REPORTING-BUGS
}

function build() {
    printf "\nStarting to build the deb packages\n\n"
    fakeroot make-kpkg --initrd --revision=$REVISION kernel_image kernel_headers -j $JOBS
}

function save_deb() {
    popd
    mkdir -p ../$FOLDER
    cp *.deb ../$FOLDER
}

function clean() {
    cd $BASEDIR
    if [ -d "tmp_folder" ]
    then
        rm -rf "tmp_folder"
    fi
}

function help() {
    printf "Small script that help us to build a linux kernel.\nBellow you can find the options of the script\n\n\t-u url for kernel source code\n\t-f deb output folder(default=debs)\n\t-c wheter you want to use the previous build or not(default=false)\n\t-C use it if you want to disable ccache(default=enabled) \n\t-r change the revision of the resulting deb files(default=0.1.papagalu)\n\t-j number of Jobs(default=32)\n\t-h display this output message\n"
}

while getopts "f:u:C:c:r:j:h" opt; do
    case $opt in
      f)
        FOLDER=$OPTARG
        ;;
      u)
        URL=$OPTARG
        ;;
      C)
        CCACHE=false
        ;;
      c)
        CLEAN=true
        ;;
      j)
        JOBS=$OPTARG
        ;;
      r)
        REVISION=$OPTARG
        ;;
      h)
        help
        exit 0
        ;;
      \?)
        echo "Invalid option: -$OPTARG"
        echo "Use -h for help"
        exit 3
        ;;
    esac
done

if [ ! $URL ]
then
    printf "\n-u flag is mandatory\n"
    exit 1
fi

pushd $BASEDIR

if [ -d "tmp_folder" ]
then 
    pushd "tmp_folder"
else
    mkdir "tmp_folder" && pushd "tmp_folder"
fi

install_deps
download
extract
prepare
build
save_deb

if [ $CLEAN = true ]
then
    clean
fi
