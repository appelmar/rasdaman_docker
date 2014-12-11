#!/bin/bash
export IMAGE_TAG=rasdaman-img
export CONTAINER_TAG=rasdaman-dev1
docker stop $CONTAINER_TAG
docker rm $CONTAINER_TAG
#docker rmi $IMAGE_TAG
docker build --rm=true --tag="$IMAGE_TAG" .


docker run -d --name="$CONTAINER_TAG" -h $CONTAINER_TAG -p 21210:22 -p 21211:8080 -p 21212:7001 -p 21213:5432 -v /var/home/marius/Desktop/shared:/opt/rasdaman/data $IMAGE_TAG 



