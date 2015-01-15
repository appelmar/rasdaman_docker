#!/bin/bash
while true; do
    read -p "WARNING: This will delete all docker containers and images including corresponding data. This is intended for development purposes only. DO YOU REALLY WANT THAT? Type y or n: " yn
    case $yn in
        [Yy]* ) break;;
        * ) exit;;
    esac
done
while true; do
    read -p "ARE YOU SURE??? Type yes: " yn
    case $yn in
        "yes" ) docker stop $(docker ps -a -q) ; docker rm $(docker ps -a -q) ; docker rmi $(docker images -q) ; break;;
        * ) exit;;
    esac
done
