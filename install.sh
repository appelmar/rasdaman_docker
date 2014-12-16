#!/bin/bash
export IMAGE_TAG=rasdaman-img
export CONTAINER_TAG=rasdaman-dev1

echo "Installation script for creating a Docker image and container running Rasdaman started.Building the image requires downloading lots of package dependencies and thus might take up to 15 minutes."
read -p "Are you sure you want to continue now? Type y or n: " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

docker stop $CONTAINER_TAG
docker rm $CONTAINER_TAG
docker rmi $IMAGE_TAG
docker build --rm=true --tag="$IMAGE_TAG" . && echo "Docker image $IMAGE_TAG build successfully!"
rm -R -f ~/docker.${CONTAINER_TAG}
mkdir ~/docker.${CONTAINER_TAG}

echo "Container $CONTAINER_TAG will be started for the first time now..."
docker run -d --name="$CONTAINER_TAG" -h $CONTAINER_TAG -m="1g" --lxc-conf="lxc.cgroup.cpuset.cpus = 0" -p 21210:22 -p 21211:8080 -p 21212:7001 -p 21213:5432 -v ~/docker.${CONTAINER_TAG}:/opt/shared $IMAGE_TAG 
echo "Waiting a minute until web applications have been deployed."
sleep 60
docker stop $CONTAINER_TAG && echo "Finished. You can now start the container by running docker start $CONTAINER_TAG"

