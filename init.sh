echo -e '\e[92m//////// --- Creando certificados --- ////////\e[39m'
cryptogen generate --config ./crypto-config.yaml

echo -e '\n\n\e[92m//////// --- Creando bloque genesis --- ////////\e[39m'
export FABRIC_CFG_PATH=$PWD
configtxgen -profile ThreeOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block

echo -e '\n\n\e[92m/////// --- Creando canal Caixabank-Alastria --- ////////\e[39m'
configtxgen -profile AlastriaCaixabankChannel -outputCreateChannelTx ./channel-artifacts/caixabankChannel.tx -channelID caixabankChannel

echo -e '\n\n\e[92m/////// --- Creando canal Silk-Alastria --- ////////\e[39m'
configtxgen -profile AlastriaSilkChannel -outputCreateChannelTx ./channel-artifacts/silkChannel.tx -channelID silkChannel

echo -e '\n\n\e[92m//////// --- Creando Anchor Peer Caixabank --- ////////\e[39m'
configtxgen -profile AlastriaCaixabankChannel -outputAnchorPeersUpdate ./channel-artifacts/CaixabankMSPanchors.tx -channelID caixabankChannel -asOrg CaixabankMSP

echo -e '\n\n\e[92m//////// --- Creando Anchor Peer Silk --- ////////\e[39m'
configtxgen -profile AlastriaSilkChannel -outputAnchorPeersUpdate ./channel-artifacts/SilkMSPanchors.tx -channelID silkChannel -asOrg SilkMSP

echo -e '\n\n\e[92m//////// --- Creando Anchor Peer Alastria-Caixabank --- ////////\e[39m'
configtxgen -profile AlastriaCaixabankChannel -outputAnchorPeersUpdate ./channel-artifacts/AlastriaMSPCaixabankMSPanchors.tx -channelID caixabankChannel -asOrg AlastriaMSP

echo -e '\n\n\e[92m//////// --- Creando Anchor Peer Alastria-Silk --- ////////\e[39m'
configtxgen -profile AlastriaSilkChannel -outputAnchorPeersUpdate ./channel-artifacts/AlastriaMSPSilkMSPanchors.tx -channelID silkChannel -asOrg AlastriaMSP
