docker-compose -f docker-compose-cli.yaml down --volumes
sudo rm -rf channel-artifacts/* && sudo rm -rf crypto-config/*
sudo rm scripts/*.block
cd upscale && sudo ./clean.sh

