FROM debian:11.7-slim

LABEL maintainer "zhouyueqiu <zhouyueqiu@easycorp.ltd>"

ARG MIRROR
ENV OS_ARCH="amd64" \
    OS_NAME="debian-11" \
    HOME_PAGE="www.zentao.net"

COPY debian/prebuildfs /

ENV TZ=Asia/Shanghai

RUN install_packages jq curl wget zip unzip s6 pwgen cron netcat ca-certificates vim-tiny patch

# Install internal php
RUN . /opt/easysoft/scripts/libcomponent.sh && component_unpack "php" "7.4.28" -c 934dd0320ee217465f6a8496b0858d120c3fd45b413f1c9ff833731a848cefa7

# Install php-ext-ioncube
RUN . /opt/easysoft/scripts/libcomponent.sh && component_unpack "php-ext-ioncube" "11.0.1" -c 9a6ee08aa864f2b937b9a108d3ec8679ae3a5f08f92a36caf5280520432315ad

# Install apache
RUN . /opt/easysoft/scripts/libcomponent.sh && component_unpack "apache" "2.4.53-fix" -c 46142923f1e74406b6d2a2eb8ed6f61289f30607eaac3c3b9b1cb83c156fdb33

# Install su-exec
RUN . /opt/easysoft/scripts/libcomponent.sh && component_unpack "su-exec" "0.2" -c 687d29fd97482f493efec73a9103da232ef093b2936a341d85969bc9b9498910

# Install render-template
RUN . /opt/easysoft/scripts/libcomponent.sh && component_unpack "render-template" "1.0.1-10" -c 5e410e55497aa79a6a0c5408b69ad4247d31098bdb0853449f96197180ed65a4

# Install mysql-client
RUN . /opt/easysoft/scripts/libcomponent.sh && component_unpack "mysql-client" "10.5.15-20220817" -c c4f82cb5b66724dd608f0bafaac400fc0d15528599e8b42be5afe8cedfd16488

# Install git for devops
RUN . /opt/easysoft/scripts/libcomponent.sh && component_unpack "git" "2.30.2" -c 02202e4bd530cbd090f1181b4cb8800a8547d4a9893bd3343542e541b28d1d7e

# Install gitlab token cli
RUN . /opt/easysoft/scripts/libcomponent.sh && component_unpack "gt" "1.3" -c 0a76eb4fc59868184e6d140b3fa81d9bdd5adb4e8dbbcb8649269464d323299d

# Install jenkins token cli
RUN . /opt/easysoft/scripts/libcomponent.sh && component_unpack "jt" "0.4" -c 0a680ed8d79fd72892f09c8894d71abe35cd9726f49ba9b13a131eca00b35440

# Install zentao
ARG VERSION
ENV ZENTAO_VER=${VERSION}
ENV EASYSOFT_APP_NAME="ZenTao $ZENTAO_VER"

SHELL ["/bin/bash", "-c"] 
RUN . /opt/easysoft/scripts/libcomponent.sh && z_download "zentao" "${ZENTAO_VER}"

# Clear apahce vhost config
RUN rm -rf /etc/apache2/sites-available/* /etc/apache2/sites-enabled/*

# Copy apache,php and gogs config files
COPY debian/rootfs /

# Apply patch
RUN bash -x /apps/zentao/patch/patch.sh

# Copy zentao-pass source code
WORKDIR /apps/zentao
RUN chown www-data.www-data /apps/zentao -R \
    && a2dismod authz_svn dav_svn

EXPOSE 80

# Persistence directory
VOLUME [ "/data"]

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
