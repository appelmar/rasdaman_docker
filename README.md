rasdaman_docker
===============
A Docker image for running Rasdaman including petascope and rasgeo extensions.

# Prerequisites
- Docker.io 
- At least 4 gigabytes of secondary storage

# Instructions
1. If not yet done, install Docker, e.g. by `sudo apt-get upgrade && sudo apt-get install docker.io`
2. Download the source by `git clone https://github.com/mappl/rasdaman_docker`
3. Make relevant scripts executable `chmod +x install.sh start.sh stop.sh`
4. If you do not want to use the default settings for docker image and container names, hostnames, and port mapping, you may want to edit the docker run command in install.sh
5. Run setup.sh `./install.sh`
6. The image will be built and a corresponding container will be created automatically. Some first time initializations (e.g. Tomcat web application deployment) will be performed during a first run before the container is finally stopped again.  
7. You can now start and stop the container whenever you like via `./start.sh` and `./stop.sh` respectively.
8. Once started, you can log in to the container via ssh using `ssh -p 21210 rasdaman@localhost`
9. Run the demo script `./demo.sh` which inserts official sample data.
10. From the host machine, try to access the inserted data via WCS using the URL `http://localhost:21211/rasdaman/ows/wcs2?service=WCS&version=2.0.1&request=DescribeCoverage&coverageid=msat_cov` or`http://localhost:21211/rasdaman/ows/wcs2?service=WCS&version=2.0.1&request=GetCoverage&coverageid=msat_cov&format=image/tiff` for DescribeCoverage and GetCoverage requests respectively.



# Limitations
This is a preliminary version, some open issues are:
- Some parts of the rasgeo extension including WMS initialization and pyramid computation are currently not working
- Rasdaman server configuration is not yet editable as setup.sh arguments
- Docker run parameters like port mappings, hostnames, and mounted volumes is not yet editable as install.sh arguments
- Data directory of Postgres is currently not accessible for the host system
