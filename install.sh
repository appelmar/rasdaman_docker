#!/bin/bash
# TODO: Add command line options for
# - docker build rm parameter (for deletion of intermediate images)
# - IMAGE + CONTAINER TAGs
# - PORTS
# - volume


export IMAGE_TAG=rasdaman-img
export CONTAINER_TAG=rasdaman-dev1

echo -e "Installation script for creating a Docker image and container running Rasdaman started. Building the image requires downloading lots of package dependencies and thus might take up to 30 minutes.\n"
read -p "Are you sure you want to continue now? Type y or n: " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

docker stop $CONTAINER_TAG
docker rm $CONTAINER_TAG
#docker rmi $IMAGE_TAG
docker build --rm=true --tag="$IMAGE_TAG" . && echo "Docker image $IMAGE_TAG build successfully!"
rm -R -f ~/docker.${CONTAINER_TAG}
mkdir ~/docker.${CONTAINER_TAG}

echo -e "Container $CONTAINER_TAG will be started for the first time now..."
docker run -d --name="$CONTAINER_TAG" -h $CONTAINER_TAG -p 21210:22 -p 21211:8080 -p 21212:7001 -p 21213:5432 -v ~/docker.${CONTAINER_TAG}:/opt/shared $IMAGE_TAG 

# Example with limited CPUs: 
# docker run -d --name="$CONTAINER_TAG" -h $CONTAINER_TAG --cpuset=$(seq -s, 0 1 2) -p 21210:22 -p 21211:8080 -p 21212:7001 -p 21213:5432 -v ~/docker.${CONTAINER_TAG}:/opt/shared $IMAGE_TAG 


echo -e "DONE. You can now login to the container via ssh."
#sleep 60
#docker stop $CONTAINER_TAG && echo "Finished. You can now start the container by running docker start $CONTAINER_TAG"

