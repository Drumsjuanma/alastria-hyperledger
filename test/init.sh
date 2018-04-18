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
    
DOMAIN="$1"
NAME=${DOMAIN^}

if ( [ "$NAME" = "Alastria" ] ); then
    echo "Nodo Alastria"
    
    echo '
################################################################################
# Profiles
################################################################################
Profiles:
    AlastriaGenesis:
        Orderer:
            <<: *OrdererDefaults
            Organizations:
                - *OrdererOrg
        Consortiums:
            SampleConsortium:
                Organizations:
                    - *Alastria
################################################################################
# Orderers
################################################################################
OrdererOrgs:
  - Name: Orderer
    Domain: alastria.com
    Specs:
      - Hostname: orderer
      
################################################################################
# Peers
################################################################################      
PeerOrgs:
  - Name: '$NAME'
    Domain: '$DOMAIN'.alastria.com
    Template:
      Count: 1
    Users:
      Count: 1' > crypto-config.yaml
      
      
   echo '

################################################################################
# organizations
################################################################################
Organizations:
    - &'$NAME'
        Name: '$NAME'MSP
        ID: '$NAME'MSP
        MSPDir: crypto-config/peerOrganizations/'$DOMAIN'.alastria.com/msp

        AnchorPeers:
            - Host: peer0.'$DOMAIN'.alastria.com
              Port: 7051
################################################################################
#   SECTION: Orderer
################################################################################
Orderer: &OrdererDefaults
    OrdererType: solo
    Addresses:
        - orderer.alastria.com:7050
    BatchTimeout: 2s
    BatchSize:
        MaxMessageCount: 10
        AbsoluteMaxBytes: 99 MB
        PreferredMaxBytes: 512 KB

    Kafka:
        Brokers:
            - 127.0.0.1:9092

    Organizations:
' > configtx.yaml
      
      
      
    
else
    echo '
    ################################################################################
    # Peers
    ################################################################################
    PeerOrgs:
      - Name: '$NAME'
        Domain: '$DOMAIN'.alastria.com
        Template:
          Count: 1
        Users:
          Count: 1
     ' > crypto-config.yaml


     echo '
    ################################################################################
    # organizations
    ################################################################################
    Organizations:
        - &'$NAME'
            Name: '$NAME'MSP
            ID: '$NAME'MSP
            MSPDir: crypto-config/peerOrganizations/'$DOMAIN'.alastria.com/msp

            AnchorPeers:
                - Host: peer0.'$DOMAIN'.alastria.com
                  Port: 7051
    ' > configtx.yaml
    
fi


