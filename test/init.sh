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
PORT1="$2"
PORT2="$3"

mkdir nodo-$DOMAIN
mkdir nodo-$DOMAIN/channel-artifacts

if ( [ "$NAME" = "Alastria" ] ); then
    echo "Nodo Alastria"
    
    echo '
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
      Count: 1' > nodo-$DOMAIN/crypto-config.yaml
      
      
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
# organizations
################################################################################
Organizations:
    - &OrdererOrg
        Name: OrdererOrg
        ID: OrdererMSP
        MSPDir: crypto-config/ordererOrganizations/alastria.com/msp


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
' > nodo-$DOMAIN/configtx.yaml

	

	echo '
version: "2"

volumes:
  orderer.alastria.com:
  peer0.alastria.alastria.com:

networks:
  byfn:

services:
  orderer.alastria.com:
    container_name: orderer.alastria.com
    image: hyperledger/fabric-orderer:$IMAGE_TAG
    environment:
      - ORDERER_GENERAL_LOGLEVEL=debug
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_GENESISMETHOD=file
      - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      # enabled TLS
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric
    command: orderer
    volumes:
      - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
      - ./crypto-config/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp:/var/hyperledger/orderer/msp
      - ./crypto-config/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/tls/:/var/hyperledger/orderer/tls
      - orderer.alastria.com:/var/hyperledger/production/orderer
    ports:
      - 7050:7050
    networks:
      - byfn

  peer0.alastria.alastria.com:
    container_name: peer0.alastria.alastria.com
    extends:
      file: ../base/peer-base.yaml
      service: peer-base
    environment:
      - CORE_PEER_ID=peer0.alastria.alastria.com
      - CORE_PEER_ADDRESS=peer0.alastria.alastria.com:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.alastria.alastria.com:7051
      - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.alastria.alastria.com:7051
      - CORE_PEER_LOCALMSPID=AlastriaMSP
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/alastria.alastria.com/peers/peer0.alastria.alastria.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/alastria.alastria.com/peers/peer0.alastria.alastria.com/tls:/etc/hyperledger/fabric/tls
      - peer0.alastria.alastria.com:/var/hyperledger/production
    ports:
      - '$PORT1':7051
      - '$PORT2':7053
    networks:
      - byfn



  cli_alastria:
    container_name: cli-alastria
    image: hyperledger/fabric-tools:$IMAGE_TAG
    tty: true
    environment:
      - GOPATH=/opt/gopath
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_LOGGING_LEVEL=DEBUG
      - CORE_PEER_ID=cli
      - CORE_PEER_ADDRESS=peer0.alastria.alastria.com:7051
      - CORE_PEER_LOCALMSPID=AlastriaMSP
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alastria.alastria.com/peers/peer0.alastria.alastria.com/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alastria.alastria.com/peers/peer0.alastria.alastria.com/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alastria.alastria.com/peers/peer0.alastria.alastria.com/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alastria.alastria.com/users/Admin@alastria.alastria.com/msp
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    volumes:
      - /var/run/:/host/var/run/
      - ./chaincode/:/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go
      - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
      - ./scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/
      - ./channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts
      - ./upscale/:/opt/gopath/src/github.com/hyperledger/fabric/peer/upscale
    depends_on:
      - orderer.alastria.com
      - peer0.alastria.alastria.com
    networks:
      - byfn' > nodo-$DOMAIN/docker-compose-cli.yaml

      
    
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
     ' > nodo-$DOMAIN/crypto-config.yaml


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
    ' > nodo-$DOMAIN/configtx.yaml


	echo '
version: "2"

volumes:
  peer0.'$DOMAIN'.alastria.com:

networks:
  byfn:

services:

  peer0.'$DOMAIN'.alastria.com:
    container_name: peer0.'$DOMAIN'.alastria.com
    extends:
      file: ../base/peer-base.yaml
      service: peer-base
    environment:
      - CORE_PEER_ID=peer0.'$DOMAIN'.alastria.com
      - CORE_PEER_ADDRESS=peer0.'$DOMAIN'.alastria.com:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.'$DOMAIN'.alastria.com:7051
      - CORE_PEER_LOCALMSPID='$NAME'MSP
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/'$DOMAIN'.alastria.com/peers/peer0.'$DOMAIN'.alastria.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/'$DOMAIN'.alastria.com/peers/peer0.'$DOMAIN'.alastria.com/tls:/etc/hyperledger/fabric/tls
      - peer0.'$DOMAIN'.alastria.com:/var/hyperledger/production
    ports:
      - '$PORT1':7051
      - '$PORT2':7053
    networks:
      - byfn  

  '$DOMAIN'-cli:
    container_name: cli-'$DOMAIN'
    image: hyperledger/fabric-tools:$IMAGE_TAG
    tty: true
    stdin_open: true
    environment:
      - GOPATH=/opt/gopath
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      #- CORE_LOGGING_LEVEL=INFO
      - CORE_LOGGING_LEVEL=DEBUG
      - CORE_PEER_ID=cli-'$DOMAIN'
      - CORE_PEER_ADDRESS=peer0.'$DOMAIN'.alastria.com:7051
      - CORE_PEER_LOCALMSPID='$NAME'MSP
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/'$DOMAIN'.alastria.com/peers/peer0.'$DOMAIN'.alastria.com/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/'$DOMAIN'.alastria.com/peers/peer0.'$DOMAIN'.alastria.com/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/'$DOMAIN'.alastria.com/peers/peer0.'$DOMAIN'.alastria.com/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/'$DOMAIN'.alastria.com/users/Admin@'$DOMAIN'.alastria.com/msp
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: /bin/bash
    volumes:
      - /var/run/:/host/var/run/
      - ./chaincode/:/opt/gopath/src/github.com/chaincode
      - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
      - ./scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/
      - ./upscale/:/opt/gopath/src/github.com/hyperledger/fabric/peer/upscale
    depends_on:
      - peer0.'$DOMAIN'.alastria.com
    networks:
      - byfn' > nodo-$DOMAIN/docker-compose-cli.yaml

fi





echo -e '\e[92m//////// --- Creando certificados --- ////////\e[39m'

cp .env nodo-$DOMAIN
cd nodo-$DOMAIN

export FABRIC_CFG_PATH=$PWD

cryptogen generate --config crypto-config.yaml

if ( [ "$DOMAIN" = "alastria" ] ); then
    echo -e '\n\n\e[92m//////// --- Creando bloque genesis --- ////////\e[39m'
    configtxgen -profile AlastriaGenesis  -outputBlock ./channel-artifacts/genesis.block
fi

echo 'docker exec -it cli-'$DOMAIN' bash' > cliConnect.sh
chmod +x cliConnect.sh


echo '
#!/bin/bash
set -u
set -e

IMAGETAG="latest"
IMAGE_TAG=$IMAGETAG docker-compose -f docker-compose-cli.yaml up -d

' > start.sh

chmod +x start.sh


