FROM debian:latest

MAINTAINER palle

RUN apt update
RUN apt-get install -y apache2 nano htop wget git apt-utils make wget sudo cron
RUN apt-get install -y libapache2-mod-perl2 libdbd-mysql-perl libtimedate-perl libnet-dns-perl libnet-ldap-perl
RUN apt-get install -y libio-socket-ssl-perl libpdf-api2-perl libdbd-mysql-perl libsoap-lite-perl libtext-csv-xs-perl
RUN apt-get install -y libjson-xs-perl libapache-dbi-perl libxml-libxml-perl libxml-libxslt-perl libyaml-perl
RUN apt-get install -y libdigest-md5-perl libarchive-zip-perl libcrypt-eksblowfish-perl libencode-hanextra-perl libmail-imapclient-perl libtemplate-perl
RUN apt-get install -y libdbd-odbc-perl libdbd-pg-perl

RUN wget http://ftp.otrs.org/pub/otrs/otrs-5.0.14.tar.gz
RUN tar xfz /otrs-5.0.14.tar.gz
RUN rm /otrs-5.0.14.tar.gz
RUN mv otrs-5.0.14 /opt/otrs

RUN cp /opt/otrs/Kernel/Config.pm.dist /opt/otrs/Kernel/Config.pm
RUN cp /opt/otrs/var/cron/otrs_daemon.dist /opt/otrs/var/cron/otrs_daemon

RUN useradd -d /opt/otrs/ -c 'OTRS user' otrs
RUN usermod -G www-data otrs

COPY Config.pm /opt/otrs/Kernel/
COPY apache2-perl-startup.pl /opt/otrs/perl/

RUN perl /opt/otrs/bin/otrs.SetPermissions.pl --otrs-user=otrs --web-group=www-data /opt/otrs

#RUN sudo -u otrs /opt/otrs/bin/Cron.sh start


# Configure Apache2 variable envir
ENV APACHE_RUN_USER     www-data
ENV APACHE_RUN_GROUP    www-data
ENV APACHE_LOG_DIR      /var/log/apache2
ENV APACHE_PID_FILE     /var/run/apache2.pid
ENV APACHE_RUN_DIR      /var/run/apache2f
ENV APACHE_LOCK_DIR     /var/lock/apache2
ENV APACHE_LOG_DIR      /var/log/apache2

RUN /usr/sbin/a2enmod ssl
RUN /usr/sbin/a2enmod perl
RUN /usr/sbin/a2enmod deflate
RUN /usr/sbin/a2enmod filter
RUN /usr/sbin/a2enmod headers

RUN ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/conf-enabled/zzz_otrs.conf &&\
    apt-get autoremove -y &&\
    apt-get clean

RUN su -c "/opt/otrs/bin/otrs.Daemon.pl start" -s /bin/bash otrs

RUN sudo -u otrs /opt/otrs/bin/Cron.sh start

# Expose ports
EXPOSE 80 443 3306

# apache2 start
ENTRYPOINT [ "/usr/sbin/apache2", "-D", "FOREGROUND" ]

