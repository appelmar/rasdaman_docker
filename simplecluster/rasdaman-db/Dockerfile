FROM ubuntu:12.04
MAINTAINER Marius Appel <marius.appel@uni-muenster.de>


ENV HOSTNAME rasdaman-db

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
	postgresql-9.1 \
	vim \
	supervisor 




# create rasdaman user with credentials: rasdaman:rasdaman
RUN adduser --gecos "" --disabled-login --home /home/rasdaman rasdaman \
   && echo  "rasdaman:rasdaman" | chpasswd \
   && adduser rasdaman sudo # add to sudo group

   
# change login credentials for root and postgres users
RUN echo 'root:xxxx.xxxx.xxxx' | chpasswd && echo 'postgres:xxxx.xxxx.xxxx' | chpasswd


# Configure SSH
RUN mkdir /var/run/sshd 
RUN echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config




# Adjust PostgreSQL configuration
RUN echo "host all  all    0.0.0.0/0   trust" >> /etc/postgresql/9.1/main/pg_hba.conf 
RUN echo "local all  all      peer" >> /etc/postgresql/9.1/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.1/main/postgresql.conf # should be replaced with localhost in production
RUN /etc/init.d/postgresql start 



COPY ./container_startup.sh /opt/
RUN chmod 0777 /opt/container_startup.sh
COPY ./supervisord.conf /etc/supervisor/conf.d/
COPY ./pgconfig.sh  /home/rasdaman/pgconfig.sh
RUN chmod 0777 /home/rasdaman/pgconfig.sh


EXPOSE 22 5432

CMD ["/usr/bin/supervisord"]
