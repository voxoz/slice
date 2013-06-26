#!/bin/sh

NODE=${1:-"instance_manager"}
BIN="rels/$NODE/node/bin/node"

$BIN attach

