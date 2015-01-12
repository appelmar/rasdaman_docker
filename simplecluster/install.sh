#!/bin/bash


export IMAGE_TAG=rasdaman-node
export IMAGE_TAG_DB=rasdaman-db


echo -e "Installation script for creating a simple Rasdaman Docker cluster. Building images requires downloading lots of package dependencies and thus might take up to 30 minutes.\n"
read -p "Are you sure you want to continue now? Type y or n: " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

sudo docker stop rasdaman-n1
sudo docker stop rasdaman-n2
sudo docker stop rasdaman-n3
sudo docker rm rasdaman-n1
sudo docker rm rasdaman-n2
sudo docker rm rasdaman-n3

docker stop rasdaman-db
docker rm rasdaman-db

# Build and start DB server first
cd rasdaman-db
sudo docker build --rm=false --tag="$IMAGE_TAG_DB" . && echo "Docker image $IMAGE_TAG_DB build successfully!"

echo -e "Container rasdaman-db will be started..."
docker run -d --name="rasdaman-db" -h "rasdaman-db" -p 22200:22 -p 22210:5432  $IMAGE_TAG_DB 




cd ..
docker build --rm=false --tag="$IMAGE_TAG" . && echo "Docker image $IMAGE_TAG build successfully!"



# Ports: 2220x SSH, 2221x Postgres, 2222x Rasdaman, 2223x Tomcat, x represents node number where 0 is the database server

echo -e "Container rasdaman-n1 will be started..."
docker run -d --name="rasdaman-n1" -h "rasdaman-n1"  --link rasdaman-db:rasdaman-db -p 22201:22 -p 22231:8080 -p 22221:7001 $IMAGE_TAG 
echo -e "Container rasdaman-n2 will be started..."
docker run -d --name="rasdaman-n2" -h "rasdaman-n2"  -p 22202:22 -p 22232:8080 -p 22222:7001 $IMAGE_TAG 
echo -e "Container rasdaman-n3 will be started..."
docker run -d --name="rasdaman-n3" -h "rasdaman-n3"  -p 22203:22 -p 22233:8080 -p 22223:7001 $IMAGE_TAG 

echo -e "DONE. You can now login to the containers via ssh."


