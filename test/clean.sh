NAME="$1"

docker-compose -f nodo-$NAME/docker-compose-cli.yaml down --volumes
sudo rm -rf nodo-$NAME
