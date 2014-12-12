rasdaman_docker
===============
A Docker image for running Rasdaman including petascope and rasgeo extensions.

# Prerequisites
- Docker.io 
- At least 4 gigabytes of secondary storage

# Instructions
1. If not yet done, install Docker, e.g. by `sudo apt-get upgrade && sudo apt-get install docker.io`
2. Download the source by `git clone https://github.com/mappl/rasdaman_docker`
3. make setup.sh executable `chmod +x setup.sh`
4. If you do not want to use the default settings for docker image and container names, hostnames, and port mapping, you may want to edit the docker run command in setup.sh
5. Run setup.sh `./setup.sh`
6. A container with running postgresql, tomcat6, and rasdaman has been started.Starting the docker container for the first time triggers tomcat web application deployment. It might thus take some minutes until petascope and SECORE are available. 
7. Log in to the container via ssh using `ssh -p 21210 rasdaman@localhost`
8. Run the demo script `./demo.sh` which inserts official sample data.
9. From the host machine, try to access the inserted data via WCS using the URL `http://localhost:21211/rasdaman/ows/wcs2?service=WCS&version=2.0.1&request=DescribeCoverage&coverageid=msat_cov` or`http://localhost:21211/rasdaman/ows/wcs2?service=WCS&version=2.0.1&request=GetCoverage&coverageid=msat_cov&format=image/tiff` for DescribeCoverage and GetCoverage requests respectively.



# Limitations
This is a preliminary version, some open issues are:
- Some parts of the rasgeo extension including WMS initialization and pyramid computation are currently not working
- Rasdaman server configuration is not yet editable as setup.sh arguments
- Docker run parameters like port mappings, hostnames, and mounted volumes is not yet editable as setup.sh arguments
- Data directory of Postgres is currently not accessible for the host system
