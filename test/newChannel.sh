
DOMAIN='$1'
CHANNEL_NAME='$2'
configtxgen -profile

configtxgen -profile AlastriaCaixabankChannel -outputCreateChannelTx ./channel-artifacts/caixabankChannel.tx -channelID caixabankchannel
