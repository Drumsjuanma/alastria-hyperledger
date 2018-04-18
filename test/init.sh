#!/bin/bash
set -u
set -e

MESSAGE='Usage: init.sg <mode> <node-type> <node-name>
    mode: CURRENT_HOST_IP | auto | backup
    node-type: validator | general
    node-name: NODE_NAME (example: Alastria)'
    
    
    
NAME="$1"
NODE_TYPE="$2"
NODE_NAME="$3"


echo '
PeerOrgs:
  - Name: $NAME
    Domain: $NAME.alastria.com
    Template:
      Count: 1
    Users:
      Count: 1
 ' >> crypto-config.yaml
