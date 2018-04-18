echo -e '\e[92m//////// --- Creando certificados --- ////////\e[39m'
cryptogen generate --config ./crypto-config.yaml

echo -e '\n\n\e[92m//////// --- Creando bloque genesis --- ////////\e[39m'
export FABRIC_CFG_PATH=$PWD
configtxgen -profile ThreeOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
