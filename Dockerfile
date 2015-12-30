FROM centos:7
MAINTAINER Skiychan <dev@skiy.net>
##
# Nginx: 1.9.9
# PHP  : 7.0.1
##
#Install system library
RUN yum -y install openssh-server epel-release && \
    yum -y install pwgen && \
    rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && \
    sed -i "s/UsePAM.*/UsePAM yes/g" /etc/ssh/sshd_config
#RUN yum update -y
RUN yum install -y gcc \
    gcc-c++ \
    autoconf \
    automake \
    libtool \
    make \
    cmake && \
    yum clean all

#Install PHP library
## libmcrypt-devel DIY
RUN yum install -y wget \
    zlib \
    zlib-devel \
    openssl \
    openssl-devel \
    pcre-devel \
    libxml2 \
    libxml2-devel \
    libcurl \
    libcurl-devel \
    libpng-devel \
    libjpeg-devel \
    freetype-devel \
    libmcrypt-devel \
    openssh-server \
    python-setuptools && \
    yum clean all

#Add user
RUN groupadd -r www && \
    useradd -M -s /sbin/nologin -r -g www www

#Download nginx & php
RUN mkdir -p /home/nginx-php && cd $_ && \
    wget -c -O nginx.tar.gz http://nginx.org/download/nginx-1.9.9.tar.gz && \
    wget -O php.tar.gz http://am1.php.net/get/php-7.0.1.tar.gz/from/this/mirror

#Make install nginx
RUN cd /home/nginx-php && \
    tar -zxvf nginx.tar.gz && \
    cd nginx-1.9.9 && \
    ./configure --prefix=/usr/local/nginx \
    --user=www --group=www \
    --error-log-path=/var/log/nginx_error.log \
    --http-log-path=/var/log/nginx_access.log \
    --pid-path=/var/run/nginx.pid \
    --with-pcre \
    --with-http_ssl_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --with-http_gzip_static_module && \
    make && make install

#Make install php
RUN cd /home/nginx-php && \
    tar zvxf php.tar.gz && \
    cd php-7.0.1 && \
    ./configure --prefix=/usr/local/php7 \
    --with-config-file-path=/usr/local/php7/etc \
    --with-config-file-scan-dir=/usr/local/php7/etc/php.d \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-mcrypt=/usr/include \
    --with-mysqli \
    --with-pdo-mysql \
    --with-openssl \
    --with-gd \
    --with-iconv \
    --with-zlib \
    --with-gettext \
    --with-curl \
    --with-png-dir \
    --with-jpeg-dir \
    --with-freetype-dir \
    --with-xmlrpc \
    --with-mhash \
    --enable-fpm \
    --enable-xml \
    --enable-shmop \
    --enable-sysvsem \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-mbstring \
    --enable-ftp \
    --enable-gd-native-ttf \
    --enable-mysqlnd \
    --enable-pcntl \
    --enable-sockets \
    --enable-zip \
    --enable-soap \
    --enable-session \
    --enable-opcache \
    --enable-bcmath \
    --enable-exif \
    --disable-fileinfo \
    --disable-rpath \
    --disable-ipv6 \
    --disable-debug \
    --without-pear && \
    make && make install

RUN cd /home/nginx-php/php-7.0.1 && \
    cp php.ini-production /usr/local/php7/etc/php.ini && \
    cp /home/nginx-php/php-7.0.1/sapi/fpm/php-fpm.service /usr/lib/systemd/system/php-fpm.service &&\
    cp /usr/local/php7/etc/php-fpm.conf.default /usr/local/php7/etc/php-fpm.conf && \
    cp /usr/local/php7/etc/php-fpm.d/www.conf.default /usr/local/php7/etc/php-fpm.d/www.conf



#Remove zips
RUN cd / && rm -rf /home/nginx-php

#Create web folder
VOLUME ["/usr/local/nginx"]
#ADD index.php /data/www/index.php

#Update nginx config
ADD default.conf /usr/local/nginx/conf/con.d/default.conf
ADD nginx.service /usr/lib/systemd/system/nginx.service
ADD nginx.conf /usr/local/nginx/conf/nginx.conf

RUN systemctl enable php-fpm &&\

    systemctl enable nginx 

#Start
#ADD start.sh /start.sh
#RUN chmod +x /start.sh



#ENTRYPOINT ["/start.sh"]

#Start web server
#CMD ["/bin/bash", "/start.sh"]
ADD set_root_pw.sh /set_root_pw.sh
ADD run.sh /run.sh
RUN chmod +x /*.sh
ENV AUTHORIZED_KEYS **None**
#Set port
EXPOSE 22 80 443

CMD ["/run.sh"]
