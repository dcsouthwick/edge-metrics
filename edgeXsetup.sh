#!/usr/bin/env bash
# script for getting EdgeX running on Rpi 3B


echo Installing Dependencies
sudo apt-get install -y docker docker-compose lua5.3 lua-socket lua-dkjson


# get edgeX compose yaml in rpi folder
# setup edgexfoundry
docker-compose pull
docker-compose up -d
docker-compose ps

