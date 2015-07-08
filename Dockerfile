FROM ubuntu:14.04
MAINTAINER levkov
ENV DEBIAN_FRONTEND noninteractive
ENV NOTVISIBLE "in users profile" 
RUN locale-gen en_US.UTF-8

RUN apt-get update && apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

RUN apt-get update && apt-get install graphite-web graphite-carbon postgresql libpq-dev python-psycopg2 supervisor openssh-server vim -y && \
    mkdir -p /var/run/sshd /var/log/supervisor && \
    echo 'root:ContaineR' | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile && \
    rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY conf/local_settings.py /etc/graphite/local_settings.py
COPY conf/graphite-carbon /etc/default/graphite-carbon
COPY conf/carbon.conf /etc/carbon/carbon.conf
COPY conf/storage-schemas.conf /etc/carbon/storage-schemas.conf
COPY conf/storage-aggregation.conf /etc/carbon/storage-aggregation.conf

USER postgres
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER graphite WITH PASSWORD 'password';" && \
    psql --command "CREATE DATABASE graphite WITH OWNER graphite;" && \ 
    /etc/init.d/postgresql stop
USER root
RUN /etc/init.d/postgresql start &&\
    yes "no" | graphite-manage syncdb

EXPOSE 22
CMD ["/usr/bin/supervisord"]
