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
!/usr/bin/env bash

# the purpose of this script is to deploy a Cassandra cluster

# prereq: 
#     passwordless ssh to destined nodes
#     
# example usage: <script name> -n list_of_nodes.txt

# generate config
# prepare hosts
# copy config
# start cluster

run_remote_command() {
    local HOST; local COMMAND; 
    HOST=$1
    COMMAND=$2

    ssh "$HOST $COMMAND"
}

make_config() {
    local HOSTS_LIST; local HOST_CONFIG;
    HOSTS_LIST=$1
    HOST_CONFIG=""
    CONF_FILE="/opt/cassandra/conf/cassandra.yaml"

    for HOST in $HOSTS_LIST do
        HOST_CONFIG="$HOST_CONFIG, $HOST"
    done
    

    for HOST in $HOSTS_LIST do
        run_remote_cpmmand $HOST "sed -i /cluster_name:/c\cluster_name: CloudBaseCluster \"$CONF_FILE\""
        run_remote_command $HOST "sed -i /seeds/c\- seeds: $HOST_CONFIG/ \"$CONF_FILE\""
        run_remote_command $HOST "sed -i /listen_address:/c\listen_address: $(hostname -I) \"$CONF_FILE\""
        run_remote_command $HOST "sed -i /rpc_address/c\rpc_address: $(hostname -I) \"$CONF_FILE\""
        run_remote_coammdn $HOST "sed -i /endpoint_snitch:/c\endpoint_snitch: GossipingPropertyFileSnitch \"$CONF_FILE\" " 
    done
}

copy_file() {
    local FROM; local TO
    FROM=$1
    TO=$2

    scp "$FROM $TO"
}

install_cassandra() {
    local HOSTS_LIST; local INSTALL_PATH; local URL
    HOSTS_LIST="$1"
    INSTALL_PATH="$2"
    URL="$3"

    for HOST in $HOSTS do
        copy_file cassandra.sh $HOST:/opt/
        run_remote_command $HOST "chmod +x cassandra.sh"
        run_remote_command $HOST "/opt/cassandra.sh $URL $INSTALL_PATH"
    done
    make_config
}

main() {
    local HOSTS_LIST; local INSTALL_PATH
    decalare -a HOSTS_LIST=( 1@1 2@2 3@3)
    INSTALL_PATH="/opt/"
    ULR="http://apache.javapipe.com/cassandra/3.11.0/apache-cassandra-3.11.0-bin.tar.gz"

    install_cassandra "$HOSTS_LIST" "$INSTALL_PATH" "$URL"
    make_config "$HOSTS_LIST" "$INSTALL_PATH"    
}

main
