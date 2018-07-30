FROM php:7.2-fpm

ENV REFRESHED_AT 2018-07-30

# install additional soft
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get -qq update && \
    apt-get -y install zip unzip git zlib1g-dev libmemcached-dev && \
    rm -rf /var/lib/apt/lists/*

# build redis.so
RUN git clone -b 4.1.0 https://github.com/phpredis/phpredis.git /opt/phpredis \
    && ( \
        cd /opt/phpredis \
        && phpize \
        && ./configure \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r /opt/phpredis \
    && docker-php-ext-enable redis.so

# build memcached.so
RUN git clone -b REL3_0 https://github.com/php-memcached-dev/php-memcached /opt/phpmemcached \
    && ( \
        cd /opt/phpmemcached \
        && phpize \
        && ./configure \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r /opt/phpmemcached \
    && docker-php-ext-enable memcached.so

# build xdebug.so
RUN git clone -b xdebug_2_6 https://github.com/xdebug/xdebug.git /opt/phpxdebug \
    && ( \
        cd /opt/phpxdebug \
        && phpize \
        && ./configure \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r /opt/phpxdebug \
    && docker-php-ext-enable xdebug.so

RUN echo "\
xdebug.idekey=PHPSTORM\n\
xdebug.max_nesting_level=300\n\
xdebug.remote_enable=1\n\
xdebug.remote_connect_back=1\n\
xdebug.remote_autostart=1\
" >> /usr/local/etc/php/conf.d/xdebug.ini

# build mongodb
RUN apt-get update && apt-get install -y libssl-dev
RUN cd /tmp/ && \
    curl -O https://pecl.php.net/get/mongodb-1.5.1.tgz && \
    tar zxvf mongodb-1.5.1.tgz && \
    mkdir -p /usr/src/php/ext && \
    mv mongodb-1.5.1 /usr/src/php/ext/mongodb
RUN docker-php-ext-install mongodb

# install extensions
RUN docker-php-ext-install pdo_mysql

# install composer
ENV COMPOSER_HOME=/tmp/.composer
RUN curl -XGET https://getcomposer.org/installer > composer-setup.php && \
    php composer-setup.php --install-dir=/bin --filename=composer --version=1.6.5 && \
    rm composer-setup.php
RUN usermod -u 1000 www-data && \
    mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /tmp/.composer
USER www-data
WORKDIR /var/www/html
