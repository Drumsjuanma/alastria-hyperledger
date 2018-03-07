ls
echo -e '\e[92m//////// --- Creando Canal --- ////////\e[39m'
export CHANNEL_NAME=mychannel
peer channel create -o orderer.alastria.com:7050 -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp/tlscacerts/tlsca.alastria.com-cert.pem

echo -e '\n\n\e[92m//////// --- Añadiendo Caixabank al canal --- ////////\e[39m'
 peer channel join -b mychannel.block

echo -e '\n\n\e[92m//////// --- Añadiendo Alastria al canal --- ////////\e[39m'
 CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alastria.alastria.com/users/Admin@alastria.alastria.com/msp CORE_PEER_ADDRESS=peer0.alastria.alastria.com:7051 CORE_PEER_LOCALMSPID="AlastriaMSP" CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alastria.alastria.com/peers/peer0.alastria.alastria.com/tls/ca.crt peer channel join -b mychannel.block

echo -e '\n\n\e[92m//////// --- Configurando Anchor Peer Caixabank --- ////////\e[39m'
peer channel update -o orderer.alastria.com:7050 -c $CHANNEL_NAME -f  /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/CaixabankMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp/tlscacerts/tlsca.alastria.com-cert.pem

echo -e '\n\n\e[92m//////// --- Configurando Anchor Peer Alastria --- ////////\e[39m'
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alastria.alastria.com/users/Admin@alastria.alastria.com/msp CORE_PEER_ADDRESS=peer0.alastria.alastria.com:7051 CORE_PEER_LOCALMSPID="AlastriaMSP" CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alastria.alastria.com/peers/peer0.alastria.alastria.com/tls/ca.crt peer channel update -o orderer.alastria.com:7050 -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/AlastriaMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp/tlscacerts/tlsca.alastria.com-cert.pem

echo -e '\n\n\e[92m//////// --- instalando Chaincode --- ////////\e[39m'
peer chaincode install -n test -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02

echo -e '\n\n\e[92m//////// --- Instanciando Chaincode --- ////////\e[39m'
peer chaincode instantiate -o orderer.alastria.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp/tlscacerts/tlsca.alastria.com-cert.pem -C $CHANNEL_NAME -n test -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}' -P "OR ('CaixabankMSP.member','AlastriaMSP.member')"
sleep 10 

echo -e '\n\n\e[92m//////// --- Query Chaincode --- ////////\e[39m'
peer chaincode query -C $CHANNEL_NAME -n test -c '{"Args":["query","a"]}'

echo -e '\n\n\e[92m//////// --- Invoke Chaincode --- ////////\e[39m'
peer chaincode invoke -o orderer.alastria.com:7050  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp/tlscacerts/tlsca.alastria.com-cert.pem  -C $CHANNEL_NAME -n test -c '{"Args":["invoke","a","b","10"]}'
sleep 5

echo -e '\n\n\e[92m//////// --- Query Chaincode --- ////////\e[39m'
peer chaincode query -C $CHANNEL_NAME -n test -c '{"Args":["query","a"]}'

