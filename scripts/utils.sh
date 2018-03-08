#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

#------------------------------------------------------------------
# This is a collection of bash functions used by different scripts
#------------------------------------------------------------------

#########################################################
# Set OrdererOrg.Admin globals 							#
#########################################################
setOrdererGlobals() {
        CORE_PEER_LOCALMSPID="OrdererMSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp/tlscacerts/tlsca.alastria.com-cert.pem
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/users/Admin@alastria.com/msp
}
#########################################################
# Set peer globals 										#
#########################################################
setGlobals () {
	PEER=$1
	ORG=$2
	MSP=$3

	CORE_PEER_LOCALMSPID=${MSP}
	CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORG}.alastria.com/peers/${PEER}.${ORG}.alastria.com/tls/ca.crt
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORG}.alastria.com/users/Admin@${ORG}.alastria.com/msp
	CORE_PEER_ADDRESS=${PEER}.${ORG}.alastria.com:7051		
	
	echo  CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID
	echo  CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE
	echo  CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH
	echo  CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS
	env |grep CORE
}

#########################################################
# update Anchor peers 									#
#########################################################
updateAnchorPeers() {
	PEER=$1
	ORG=$2
	MSP=$3
	setGlobals $PEER $ORG $MSP

 		set -x
	peer channel update -o orderer.alastria.com:7050 -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA 
		set +x
	
	echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
	sleep 3
	echo
}

#########################################################
# Join Channel 											#
#########################################################
joinChannelWithRetry () {
	PEER=$1
	ORG=$2
	MSP=$3
	setGlobals $PEER $ORG $MSP

        set -x
	peer channel join -b $CHANNEL_NAME.block 
        set +x
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.org${ORG} failed to join the channel, Retry after $DELAY seconds"
		sleep $DELAY
		joinChannelWithRetry $PEER $ORG
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to Join the Channel"
}

#########################################################
# Install Chaincode 									#
#########################################################
installChaincode () {
	PEER=$1
	ORG=$2
	MSP=$3
	CHAINCODE_NAME=$4
	CHAINCODE_PATH=$5
	CHAINCODE_VERSION=$6

	setGlobals $PEER $ORG $MSP
        set -x
	peer chaincode install -n ${CHAINCODE_NAME} -v ${CHAINCODE_VERSION} -p ${CHAINCODE_PATH} 
        set +x
	res=$?
	cat log.txt
	verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has Failed"
	echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
	echo
}


#########################################################
# instantiate Chaincode 								#
#########################################################
instantiateChaincode () {
	PEER=$1
	ORG=$2
	MSP=$3
	CHAINCODE_NAME=$4
	CHAINCODE_PATH=$5
	CHAINCODE_VERSION=$6

            set -x
	peer chaincode instantiate -o orderer.alastria.com:7050 --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CHAINCODE_NAME}  -v ${CHAINCODE_VERSION} -c '{"Args":["init","a","100","b","200"]}' -P "OR	('${CHAINCODE_VERSION}.member','AlastriaMSP.member')" >&log.txt
            set +x

	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

#########################################################
# Upgrade Chaincode 									#
#########################################################
upgradeChaincode () {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG

    set -x
    peer chaincode upgrade -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')"
    set +x
    res=$?
    cat log.txt
    verifyResult $res "Chaincode upgrade on org${ORG} peer${PEER} has Failed"
    echo "===================== Chaincode is upgraded on org${ORG} peer${PEER} ===================== "
    echo
}


#########################################################
# Chaincode Query 									#
#########################################################
chaincodeQuery () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  EXPECTED_RESULT=$3
  echo "===================== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s)-starttime)) secs"
     set -x
     peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >&log.txt
     set +x
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

#########################################################
# Fetch Channel Config 									#
#########################################################
# fetchChannelConfig <channel_id> <output_json>
# Writes the current channel config for a given channel to a JSON file
fetchChannelConfig() {
  	CHANNEL=$1
  	OUTPUT=$2

  	setOrdererGlobals

  	echo "Fetching the most recent configuration block for the channel"

  		set -x
    peer channel fetch config config_block.pb -o orderer.alastria.com:7050 -c $CHANNEL --tls --cafile $ORDERER_CA
    	set +x


  echo "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
  configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > "${OUTPUT}"
  set +x
}


#########################################################
# Sign ConfigTx As Peer Org 							#
#########################################################
# signConfigtxAsPeerOrg <org> <configtx.pb>
# Set the peerOrg admin of an org and signing the config update
signConfigtxAsPeerOrg() {
    PEER=$1
    ORG=$2
    MSP=$3
    TX=$4

    setGlobals $PEER $ORG $MSP
    	set -x
    peer channel signconfigtx -f "${TX}"
    	set +x
}

#########################################################
# Create Config Update 		 							#
#########################################################
# createConfigUpdate <channel_id> <original_config.json> <modified_config.json> <output.pb>
# Takes an original and modified config, and produces the config update tx which transitions between the two
createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config > original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config > modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb > config_update.pb
  configtxlator proto_decode --input config_update.pb  --type common.ConfigUpdate > config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope > "${OUTPUT}"
  set +x
}

chaincodeInvoke () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
                set +x
	else
                set -x
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
                set +x
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on peer${PEER}.org${ORG} failed "
	echo "===================== Invoke transaction on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}0000
