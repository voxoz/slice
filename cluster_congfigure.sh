#!/bin/bash

NODE=`hostname`

function setup_node {
   cp prod/$NODE/sys.config rels/$1/node/releases/1/sys.config
   cp prod/$NODE/vm.args rels/$1/node/releases/1/vm.args
}

setup_node instance_manager
