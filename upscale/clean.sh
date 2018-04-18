rm -rf channel-artifacts/* &&  rm -rf crypto-config && rm -rf config/ 
mv configtx.yaml 1configtx.yaml
rm config*
mv 1configtx.yaml configtx.yaml
rm update*

