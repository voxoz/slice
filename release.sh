#!/bin/bash

NODE=${1:-"instance_manager"}

function release_node {
    rm -rf rels/$1/node/lib
    rm -rf rels/$1/node/log
    rm -rf rels/$1/node/releases
    cd rels/$1
    rebar -f generate
    cd ../..
}

if [ "$NODE" == "all" ]; then
   echo "Releasing all nodes..."
   release_node insstance_manager
else
   echo "Releasing node $NODE..."
   release_node $NODE
fi

