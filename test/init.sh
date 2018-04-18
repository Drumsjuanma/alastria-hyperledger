#!/bin/bash
set -u
set -e

MESSAGE='Usage: init.sg <mode> <node-type> <node-name>
    mode: CURRENT_HOST_IP | auto | backup
    node-type: validator | general
    node-name: NODE_NAME (example: Alastria)' 
    

if ( [ $# -ne 3 ] ); then
    echo "$MESSAGE"
    exit
fi    
    
DOMAIN="$1"
NAME=${DOMAIN^}


echo '
PeerOrgs:
  - Name: '$NAME'
    Domain: '$DOMAIN'.alastria.com
    Template:
      Count: 1
    Users:
      Count: 1
 ' >> crypto-config.yaml
 
 
 echo '
Organizations:
    - &'$NAME'
        Name: '$NAME'MSP
        ID: '$NAME'MSP
        MSPDir: crypto-config/peerOrganizations/'$DOMAIN'.alastria.com/msp

        AnchorPeers:
            - Host: peer0.'$DOMAIN'.alastria.com
              Port: 7051
' >> configtx.yaml


