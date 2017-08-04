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

#!/usr/bin/env bash

# small script that installs Cassandra and starts it
# Example usage: <script name> <url to Cassandra binary>
# i chose binray installation over package one, because
# it's more self contained, logs and conf in a single place

set -x

install_deps() {
    sudo $os_PACKAGE_MANAGER update
    DEBIAN_FRONTEND=noninteractive sudo $os_PACKAGE_MANAGER install python openjdk-8-jdk openjdk-8-jre wget
}

retrieve_cassandra() {
    local URL; local BASEFILE; local INSTALL_FOLDER; local TAR_FOLDER;
    URL=$1
    BASEFILE=$(basename $URL)
    INSTALL_FOLDER=$2
    pushd $INSTALL_FOLDER
    echo $BASEFILE

    sudo wget $URL
    TAR_FOLDER=$(sudo tar tzf $BASEFILE | head -1 | cut -f1 -d"/")
    sudo tar -xzf $BASEFILE
    sudo mv $TAR_FOLDER /opt/cassandra
    sudo rm -rf $BASEFILE $TAR_FOLDER
    popd
}

main() {
    local URL; local INSTALL_FOLDER
    URL=$1
    INSTALL_FOLDER=$2
    install_deps
    retrieve_cassandra $URL $INSTALL_FOLDER
}

main $@
