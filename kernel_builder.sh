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

# Example run: kernel_builder.sh -u https://git.kernel.org/torvalds/t/linux-4.13-rc1.tar.gz

. get_os.sh
. utils.sh

get_threads() {
    local THREADS; local FLOAT
    THREADS=$(getconf _NPROCESSORS_ONLN)
    FLOAT=$(echo "1.5 * $THREADS" | bc)
    printf "%.0f" "$FLOAT"
}

install_deps() {
    printf "\nInstalling dependencies.\n\n"
    sudo "$os_PACKAGE_MANAGER" update -y
    DEBIAN_FRONTEND=noninteractive sudo "$os_PACKAGE_MANAGER" install $(get_packages) -y
    if [[ $? -ne 0 ]]; then
    printf "Couldn't install the required packages"
        exit 1
    fi
    sudo sed -i -e "s/j1/j$JOBS/g" \
         /usr/share/kernel-package/ruleset/targets/common.mk
    if [[ $CCACHE = true ]]; then
        PATH=/usr/lib/ccache:$PATH
    fi
}

download() {
    printf "\nStarting download from %s\n\n" "$URL"
    exec_with_retry "wget -nc $URL" 3 5
    if [[ $? -ne 0 ]]; then
        printf "\nDownload failed\nPossible bad URL: %s\n\n" "$URL"
        clean
        exit 2
    fi
}

extract() {
    local TAR_DIRECTORY
    printf "\nExtracting tarball\n"
    TAR_DIRECTORY=$(tar tzf ./*.tar.gz | head -1 | cut -f1 -d"/")
    tar -xz -f ./*.tar.gz --no-overwrite-dir
    if [[ $? -ne 0 ]]; then
        printf "Couldn't untar the tarball, archive might be corrupt"
        exit 3
    fi
    pushd "$TAR_DIRECTORY"
}

prepare() {
    printf "\nPreparing for compiling the kernel\n\n"
    make olddefconfig

    touch REPORTING-BUGS
}

build_deb() {
    fakeroot make-kpkg --initrd --revision="$REVISION" \
        kernel_image kernel_headers -j "$(get_threads)"
}

build_rpm() {
    make rpm -j "$(get_threads)"
}

save_package_deb() {
    popd; popd
    cp "$TMP_DIR"/*."$os_PACKAGE" "$PACKAGE_PATH"
}

save_package_rpm() {
    find ~/rpmbuild -name "*.$os_PACKAGE" | xargs -I {} cp {} "$PACKAGE_PATH"
}

clean() {
    cd "$BASEDIR" || exit 3
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}

help() {
cat << EOF
Small script that help us to build a linux kernel.
Bellow you can find the options of the script
 
    -u url for kernel source code
    -f deb output folder(default=basedir/packages)
    -c wheter you want to use the previous build or not(default=false)
    -C use it if you want to disable ccache(default=enabled)
    -r change the revision of the resulting deb files(default=0.1.papagalu)
    -j number of Jobs(default=1.5*number of threads)
    -h display this output message
EOF
}

main() {

    URL=""
    TAR_DIRECTORY=""
    CLEAN=false
    CCACHE=true
    REVISION="0.1.papagalu"
    BASEDIR=$(dirname "$0")
    PACKAGE_PATH="$BASEDIR/packages"
    TMP_DIR="tmp_folder"

    while getopts "f:u:C:c:r:j:h" opt; do
        case $opt in
            f)
                PACKAGE_PATH="$BASEDIR/$OPTARG" ;;
            u)
                URL=$OPTARG ;;
            C)
                CCACHE=false ;;
            c)
                CLEAN=true ;;
            j)
                JOBS=$OPTARG ;;
            r)
                REVISION=$OPTARG ;;
            h)
                help; exit 0 ;;
            \?)
                echo "Invalid option: -$OPTARG"
                echo "Use -h for help"
                exit 3
                ;;
        esac
    done

    if [ ! $URL ]; then
        printf "\n-u flag is mandatory\n"
        exit 1
    fi

    pushd "$BASEDIR"
    mkdir -p "$PACKAGE_PATH" || true

    mkdir $TMP_DIR || true
    pushd $TMP_DIR


    install_deps
    download
    extract
    prepare
    printf "\nStarting to build the packages\n\n"
    "build_$os_PACKAGE"
    "save_package_$os_PACKAGE"

    if [ $CLEAN = true ]; then
        clean
    fi

}

main "$@"
