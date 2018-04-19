#!/bin/bash
set -u
set -e

MESSAGE='Usage: init.sg <mode> <node-type> <node-name>
    mode: CURRENT_HOST_IP | auto | backup
    node-type: validator | general
    node-name: NODE_NAME (example: Alastria)' 
    
if ( [ $# -ne 1 ] ); then
    echo "$MESSAGE"
    exit
fi    

    
NAME="$1"

export FABRIC_CFG_PATH=$PWD

echo -e '\e[92m//////// --- Creando certificados --- ////////\e[39m'
cryptogen generate --config ./crypto-config.yaml

if ( [ "$NAME" = "alastria" ] ); then
    echo -e '\n\n\e[92m//////// --- Creando bloque genesis --- ////////\e[39m'
    configtxgen -profile AlastriaGenesis  -outputBlock ./channel-artifacts/genesis.block
fi
