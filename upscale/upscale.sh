#!/bin/bash

##################################################################################################
##################################### Script details #############################################
##################################################################################################
###         Author: Pau Aragones Sabate <paragones@itnow.es>                                    
###
###         Project: Add an organisation in an already running Hyperledger network             
###
###         Logic: Use configtxlator tool to get the genesis block of a channel,               
###             translate from block language to json, include new organisation in
###             json file, encrypt it back and publish the package to the channel if script 
###             is executed in a CLI container of an already participating organization.
###
###         Runtime: Ideally on a Hyperledger CLI container from at least version
###             1.1-rc1, due to the use of some exclusive functions of configtxlator tool.
###
###         Parameters: the channel name and the organization name is required. 
###             Pass this parameter as ./upscale.sh  $ORGANIZATION $CHANNEL_NAME
###
###         Files: Two yaml files defining the name of the organisation and 
###             the MSP configuration of that organisation
###
###################################################################################################
###################################################################################################
###################################################################################################


# This function signs the updated configuration block from one organization already present in the network and participant in the channel
function signConfiguration {
    printf "Signing the configuration update to the channel $CHANNEL_NAME..."

    peer channel signconfigtx -f config_update_in_envelope.pb

    if [ $? -ne 0 ]; then
        printf "An error during the peer channel command execution happened. The code of error was $?\n\n"
        exit
    else 
        printf "Done\nNext you should update the channel $CHANNEL_NAME from another CLI pod of another organisation already present in the blockchain.\nExecute the following command in that CLI container:\npeer channel update -f config_update_in_envelope.pb -c $CHANNEL_NAME -o \$ORDERER_URL --tls true --cafile \$CA_ORDERER\n\nThank you come again!"
    fi
}

# Check that all parameters have been introduced correctly
if [ $# -eq 0 ]; then
    printf "No arguments supplied. The channel name and the organization name is required. Pass this parameter as ./upscale.sh  \$ORGANIZATION \$CHANNEL_NAME\n"
    exit
elif [ -z "$1" ]; then
    printf "ORGANIZATION not defined. The channel name and the organization name is required. Pass this parameter as ./upscale.sh  \$ORGANIZATION \$CHANNEL_NAME\n"
    exit
elif [ -z "$2" ]; then
    printf "CHANNEL_NAME not defined. The channel name and the organization name is required. Pass this parameter as ./upscale.sh  \$ORGANIZATION \$CHANNEL_NAME\n"
    exit
fi

# Check that the CLI container has the jq tools and curl for easing the json formatting and managing
dpkg-query -W jq
if [ $? -ne 0 ]; then
    printf "jq is not installed in this environment. It is going to be installed right now...\n"
    apt-get update && apt-get install jq
    printf "jq is now installed\n"
else
    printf "jq is already installed in this environment\n"
fi

dpkg-query -W curl
if [ $? -ne 0 ]; then
    printf "curl is not installed in this environment. It is going to be installed right now...\n"
    apt-get update && apt-get install curl
    printf "curl is now installed\n"
else
    printf "curl is already installed in this environment\n"
fi

# Check that the files needed for encrypting and certificate generation do exists at the same folder with the following syntaxis: $ORGANIZATION-crypto.yaml and configtx.yaml
#   TODO

# Define variables needed for this script
CHANNEL_NAME=$2
ORGANIZATION=$1
CONFIGTXLATOR_URL=http://127.0.0.1:7059
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/alastria.com/orderers/orderer.alastria.com/msp/tlscacerts/tlsca.alastria.com-cert.pem
#export FABRIC_CFG_PATH=$PWD

printf "Setting variables values:\nCHANNEL_NAME: $CHANNEL_NAME\nORGANIZATION: $ORGANIZATION\nCONFIGTXLATOR_URL: $CONFIGTXLATOR_URL\nORDERER_CA: $ORDERER_CA\nFABRIC_CFG_PATH: $PWD\n\n"

# Generate the certificates of the new organization. It will use the configuration org-crypto.yaml
printf "Generating certificates of the new organisation..."

cryptogen generate --config=./$ORGANIZATION-crypto.yaml

printf "Done\nA new crypto-config folder should have appeared...\n\n"

# Generate the MSP and configuration details of the new organisation. This process needs to have the configtx.yaml file with the MSP info of the new organization
printf "Generating the MSP configuration of the new organisation..."

FABRIC_CFG_PATH=$PWD configtxgen -printOrg $(echo $ORGANIZATION)MSP > channel-artifacts/$ORGANIZATION.json

printf "Done\nA new json file should have appeared at channel-artifacts path.\n\n"

# Start the configtxlator tool inside the container
printf "Starting configtxlator REST API server at this url: $CONFIGTXLATOR_URL\n"

configtxlator start &

printf "Done starting server\n\n"

# Fetch the genesis block at the most recent configuration state.
printf "Fetching the latest configuration of the channel $CHANNEL_NAME..."

peer channel fetch config config_block.pb -o orderer.alastria.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA

printf "Done\nA config_block.pb protobuffer file should have appeared in the working directory\n\n"

# Translate the genesis block from protobuffer into json so that is editable. Configtxlator and jq is used for this
printf "Posting the config_block.pb to the configtxlator server $CONFIGTXLATOR_URL for translating the protobuffer block into json format..."

curl -X POST --data-binary @config_block.pb "$CONFIGTXLATOR_URL/protolator/decode/common.Block" | jq . > config_block.json

if [ $? -ne 0 ]; then
    printf "An error during the curl process happened. The code of error was $?\n"
    exit
else 
    printf "Done\nA config_block.json should have appeared in the working directory\n\n"
fi

# Isolate the current config specific information - this removes unnecessary elements from the block (header, channel info, signatures, etc...)
printf "Isolating the current config specific information..."

jq .data.data[0].payload.data.config config_block.json > config.json

if [ $? -ne 0 ]; then
    printf "An error during the jq process happened. The code of error was $?\n\n"
    exit
else 
    printf "Done\nA config.json should have appeared in the working directory with the information necessary for modification\n\n"
fi

printf "Done\nA config.json should have appeared in the working directory with the information necessary for modification\n\n"

# Append the json file we generated earlier to the config.json file
printf "Appending the $ORGANIZATION definition to the groups definition of the config.json..."

jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups":{"'$(echo $ORGANIZATION)'MSP":.[1]}}}}}' config.json ./channel-artifacts/$ORGANIZATION.json >& updated_config.json

if [ $? -ne 0 ]; then
    printf "An error during the jq process happened. The code of error was $?\n\n"
    exit
else 
    printf "Done\nAn updated_config.json should have appeared in the working directory.\n\n"
fi

# Turn config.json and updated_config.json back into protobuffer encoding
printf "Turning config.json and updated_config.json back into protobuffer encoding..."

curl -X POST --data-binary @config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > config.pb

if [ $? -ne 0 ]; then
    printf "An error during the curl process happened. The code of error was $?\n\n"
    exit
else 
    printf "Done\nA config.pb file should have appeared in the working directory.\n\n"
fi

curl -X POST --data-binary @updated_config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > updated_config.pb

if [ $? -ne 0 ]; then
    printf "An error during the curl process happened. The code of error was $?\n\n"
    exit
else 
    printf "Done\nA updated_config.pb should have appeared in the working directory.\n\n"
fi

# Find the difference between config.pb and updated_config.pb so that we isolate just the new organization information
printf "Finding the difference between config.pb and updated_config.pb so that we isolate just the new organization information..."

curl -X POST -F channel=$CHANNEL_NAME -F "original=@config.pb" -F "updated=@updated_config.pb" "${CONFIGTXLATOR_URL}/configtxlator/compute/update-from-configs" > config_update.pb

if [ $? -ne 0 ]; then
    printf "An error during the curl process happened. The code of error was $?\n\n"
    exit
else 
    printf "Done\nA new protobuffer file config_update should have appeared in the working directory\n\n"
fi

# Turn the protobuffer file config_update.pb back into json format.
printf "Translating the protobuffer file config_update.pb to json format..."

curl -X POST --data-binary @config_update.pb "$CONFIGTXLATOR_URL/protolator/decode/common.ConfigUpdate" | jq . > config_update.json

if [ $? -ne 0 ]; then
    printf "An error during the curl process happened. The code of error was $?\n\n"
    exit
else 
    printf "Done\nA config_update.json file should have appeared in the working directory\n\n"
fi

# Add the previously removed config specific information back to the new json file
printf "Adding the previously removed config specific information back to the new json file..."

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$(echo $CHANNEL_NAME)'","type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json

if [ $? -ne 0 ]; then
    printf "An error during the jq process happened. The code of error was $?\n\n"
    exit
else 
    printf "Done\nA config_update_in_envelope.json file should have appeared in the working directory\n\n"
fi

# Finally put it back into protobuffer encryption for updating the channel $CHANNEL_NAME
printf "Translating the config_update_in_envelope.json into protobuffer encryption..."

curl -X POST --data-binary @config_update_in_envelope.json "$CONFIGTXLATOR_URL/protolator/encode/common.Envelope" > config_update_in_envelope.pb

if [ $? -ne 0 ]; then
    printf "An error during the curl process happened. The code of error was $?\n\n"
    exit
else 
    printf "Done\nA config_update_in_envelope.pb file should have appeared in the working directory\n\n"
fi

# Until here, the updated configuration has been generated and ready to be signed by an organization. Suposing that we are in a CLI container, a question will be asked to the user whether the script is runing on a Docker container
printf "Next step should be signing the config_update_in_envelope.pb from a peer of an organization already present in the channel and the network intended to be expanded.\nAre you executing this script inside a CLI container of one organization? (y/n)\n"
read -p "Continue? [y/n] " yn
    case "$yn" in
        y ) signConfiguration; ;;
        n ) printf "You should execute the following command in a CLI container of another organization\npeer channel signconfigtx -f config_update_in_envelope.pb\nThank you come again! \n"; exit;;
    esac



