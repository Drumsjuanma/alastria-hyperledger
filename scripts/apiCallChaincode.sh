echo -e '\n\n\e[92m//////// --- instalando Chaincode --- ////////\e[39m'
export CHANNEL_NAME=caixabankchannel
peer chaincode install -n apiCall -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/api

echo -e '\n\n\e[92m//////// --- Instanciando Chaincode --- ////////\e[39m'
peer chaincode instantiate -o orderer.alastria.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp/tlscacerts/tlsca.alastria.com-cert.pem -C $CHANNEL_NAME -n apiCall -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}' -P "OR ('CaixabankMSP.member','AlastriaMSP.member')"
sleep 10

echo -e '\n\n\e[92m//////// --- Query Chaincode --- ////////\e[39m'
peer chaincode query -C $CHANNEL_NAME -n apiCall -c '{"Args":["query","a"]}'

echo -e '\n\n\e[92m//////// --- Invoke Chaincode --- ////////\e[39m'
peer chaincode invoke -o orderer.alastria.com:7050  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp/tlscacerts/tlsca.alastria.com-cert.pem  -C $CHANNEL_NAME -n apiCall -c '{"Args":["invoke","a","b","10"]}'
sleep 5

echo -e '\n\n\e[92m//////// --- Query Chaincode --- ////////\e[39m'
peer chaincode query -C $CHANNEL_NAME -n apiCall -c '{"Args":["query","a"]}'



