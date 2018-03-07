echo -e '\e[92m//////// --- Creando certificados --- ////////\e[39m'
cryptogen generate --config ./crypto-config.yaml

echo -e '\n\n\e[92m//////// --- Creando bloque genesis --- ////////\e[39m'
export FABRIC_CFG_PATH=$PWD
configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block

echo -e '\n\n\e[92m/////// --- Creando canal Caixabank-Alastria --- ////////\e[39m'
export CHANNEL_NAME=mychannel
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

echo -e '\n\n\e[92m//////// --- Creando Anchor Peer Caixabank --- ////////\e[39m'
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/CaixabankMSPanchors.tx -channelID $CHANNEL_NAME -asOrg CaixabankMSP

echo -e '\n\n\e[92m//////// --- Creando Anchor Peer Alastria --- ////////\e[39m'
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/AlastriaMSPanchors.tx -channelID $CHANNEL_NAME -asOrg AlastriaMSP
