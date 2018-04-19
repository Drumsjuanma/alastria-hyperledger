#!/bin/bash
set -u
set -e

echo -e '\e[42m//////// --- Iniciando Red AlastriaNet --- ////////\e[49m'

IMAGETAG="latest"
IMAGE_TAG=$IMAGETAG docker-compose -f docker-compose-cli.yaml up -d

echo -e '\e[92m//////// --- Exito --- ////////\e[39m'

