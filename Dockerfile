FROM ubuntu:12.04
MAINTAINER Marius Appel <marius.appel@uni-muenster.de>

# TODO:
# - Add tomcat6 as init.d service, otherwise tomcat doesn't work properly after a running container was stopped abnormally 
# - Add rasdaman config tool
# - Set rasdaman log dir and tomcat log dir to shared folder
# - Allow write access to shared folder for tasdaman user -> chgrp, adduser

ENV CATALINA_HOME /opt/tomcat6
ENV WEBAPPS_HOME $CATALINA_HOME/webapps
ENV RMANHOME /opt/rasdaman/
ENV HOSTNAME rasdaman-dev1
ENV JAVA_HOME /usr/lib/jvm/java-6-openjdk

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN env


# Install required software 
RUN apt-get -qq update && apt-get install --fix-missing -y --force-yes \
	ssh \
	openssh-server \
	sudo \
	wget \
	gdebi \
	git \
	git-core \
	make \
	autoconf \
	automake \
	libtool \
	gawk \
	flex \
	bison \
	g++ \
	doxygen \
	ant \
	autotools-dev \
	comerr-dev \
	libecpg-dev \
	libtiff4-dev \
	libgdal-dev \
	libgdal1-dev \
	gdal-bin \
	libncurses5-dev \
	libnetpbm10-dev \
	libffi-dev \
	libreadline-dev \
	libtool \
	m4 \
	postgresql-9.1 \
	openjdk-6-jdk \
	libsigsegv-dev \
	libedit-dev \
	libtiff-dev \
	libjpeg8-dev \
	libpng12-dev \
	libnetpbm10-dev \
	libhdf4-alt-dev \
	libnetcdf-dev \
	libsigsegv-dev \
	vim \
	supervisor \
	net-tools



RUN wget -t 3 -w 2 ftp://ftp.fu-berlin.de/unix/www/apache/tomcat/tomcat-6/v6.0.43/bin/apache-tomcat-6.0.43.tar.gz
RUN tar -xzf apache-tomcat-6.0.43.tar.gz
RUN mv apache-tomcat-6.0.43 /opt/tomcat6



# create rasdaman user with credentials: rasdaman:rasdaman
RUN adduser --gecos "" --disabled-login --home /home/rasdaman rasdaman \
   && echo  "rasdaman:rasdaman" | chpasswd \
   && adduser rasdaman sudo # add to sudo group

   
# change login credentials for root and postgres users
RUN echo 'root:xxxx.xxxx.xxxx' | chpasswd && echo 'postgres:xxxx.xxxx.xxxx' | chpasswd


# Configure SSH
RUN mkdir /var/run/sshd 
RUN echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config




# Download and build rasdaman
RUN mkdir /home/rasdaman/install && git clone -q git://kahlua.eecs.jacobs-university.de/rasdaman.git  /home/rasdaman/install
WORKDIR /home/rasdaman/install
#RUN git checkout v9.0.5 # uncomment this if you want a tagged rasdaman version
RUN autoreconf -fi  && ./configure --prefix=$RMANHOME --with-netcdf --with-hdf4 --with-wardir=$WEBAPPS_HOME
RUN make 
RUN make install



# Some neccessary rasdaman adjustments
RUN sed -i 's/=petauser/=rasdaman/g' $RMANHOME/etc/petascope.properties
RUN sed -i 's/=petapasswd/=rasdaman/g' $RMANHOME/etc/petascope.properties
RUN sed -i 's!petascope.log!/tmp/petascope.log!' $RMANHOME/etc/log4j.properties
RUN sed -i 's!/home/rasdaman/install!$RMANHOME!' $RMANHOME/bin/update_petascopedb.sh



# Adjust PostgreSQL configuration
RUN echo "host all  all    127.0.0.1/32   trust" >> /etc/postgresql/9.1/main/pg_hba.conf
#RUN echo "host all  all    0.0.0.0/0   trust" >> /etc/postgresql/9.1/main/pg_hba.conf # only for debugging!!!
RUN echo "local all  all      peer" >> /etc/postgresql/9.1/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.1/main/postgresql.conf # should be replaced with localhost in production
RUN /etc/init.d/postgresql start \
	&& su - postgres -c"psql -c\"CREATE ROLE rasdaman SUPERUSER LOGIN CREATEROLE CREATEDB UNENCRYPTED PASSWORD 'rasdaman';\"" \
	&& su - rasdaman -c"$RMANHOME/bin/create_db.sh" && su - rasdaman -c"$RMANHOME/bin/update_petascopedb.sh"





# Add persistent environment variables to container 
RUN echo "export RMANHOME=$RMANHOME" >> /etc/profile \
	&& echo "export CATALINA_HOME=$CATALINA_HOME" >> /etc/profile \
	&& echo "export PATH=\$PATH:$RMANHOME/bin" >> /etc/profile \
	&& echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile 


	
	
	
# SETUP RASGEO EXTENSTION # 

RUN mkdir /home/rasdaman/.rasdaman 
COPY ./rasconnect /home/rasdaman/.rasdaman/


# COPY SOME UTILITIES AND DEMONSTRATIONS
COPY ./demo.sh /home/rasdaman/
RUN chmod 0777 /home/rasdaman/demo.sh
COPY ./container_startup.sh /opt/
RUN chmod 0777 /opt/container_startup.sh
COPY ./supervisord.conf /etc/supervisor/conf.d/
COPY ./pgconfig.sh  /home/rasdaman/pgconfig.sh
RUN chmod 0777 /home/rasdaman/pgconfig.sh
COPY examples /home/rasdaman/examples
RUN find /home/rasdaman/examples -type d -exec chmod 0777 {} + && find /home/rasdaman/examples -type f -name "*.sh" -exec chmod 0777 {} + # Make all example scripts executable



RUN chown -R rasdaman $RMANHOME
RUN chown -R rasdaman /home/rasdaman
RUN mkdir /opt/shared # TODO: Add environment variable for shared folder
RUN chmod -R 0777 /opt/shared # Allow all users writing to shared folder # This does not work yet, maybe rights for volumes are reset during docker run?

EXPOSE 7001 8080 22 5432

CMD ["/usr/bin/supervisord"]
