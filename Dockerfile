FROM ubuntu:14.04
LABEL "org.opencontainers.image.authors"="levkov"
ENV DEBIAN_FRONTEND noninteractive
ENV NOTVISIBLE "in users profile" 
RUN locale-gen en_US.UTF-8

RUN apt-get update && apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

RUN apt-get update && apt-get install graphite-web graphite-carbon postgresql libpq-dev python-psycopg2 supervisor openssh-server vim apache2 libapache2-mod-wsgi -y && \
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

COPY scripts/mkadmin.py /usr/bin/mkadmin.py
RUN chmod 755          /usr/bin/mkadmin.py

USER postgres
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER graphite WITH PASSWORD 'password';" && \
    psql --command "CREATE DATABASE graphite WITH OWNER graphite;" && \ 
    /etc/init.d/postgresql stop
USER root
RUN /etc/init.d/postgresql start &&\
    graphite-manage syncdb --noinput &&\
    python /usr/bin/mkadmin.py && \
    /etc/init.d/postgresql stop

RUN a2dissite 000-default &&\
    cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-available &&\
    a2ensite apache2-graphite


EXPOSE 22 80 2003 2003/udp 2004 7002
CMD ["/usr/bin/supervisord"]
