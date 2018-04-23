#!/bin/bash
set -u
set -e

DOMAIN="$1"

echo -e '\e[42m//////// --- Iniciando Red AlastriaNet --- ////////\e[49m'

IMAGETAG="latest"
cd nodo-$DOMAIN
IMAGE_TAG=$IMAGETAG docker-compose -f docker-compose-cli.yaml up -d

echo -e '\e[92m//////// --- Exito --- ////////\e[39m'

