#!/bin/bash
while true; do
    read -p "WARNING: This will delete all docker containers and images including corresponding data. This is intended for development purposes only. DO YOU REALLY WANT THAT? Type y or n: " yn
    case $yn in
        [Yy]* ) docker stop $(docker ps -a -q) ; docker rm $(docker ps -a -q) ; docker rmi $(docker images -q) ; break;;
        [Nn]* ) exit;;
        * ) ;;
    esac
done
