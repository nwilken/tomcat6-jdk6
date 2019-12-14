ARG TOMCAT_VERSION=6.0.53

FROM asuuto/apache-installer:latest AS installer
ARG TOMCAT_VERSION
RUN /install-tomcat ${TOMCAT_VERSION}

FROM amazonlinux:2 AS final
LABEL maintainer="Nate Wilken <wilken@asu.edu>"
ARG TOMCAT_VERSION

RUN set -x && \
    yum update -y && \
    yum clean all && \
    rm -rf /var/cache/yum /var/log/yum.log

COPY rpm/jdk-6u45-linux-x64-rpm.bin /tmp
RUN chmod +x /tmp/jdk-6u45-linux-x64-rpm.bin && \
    /tmp/jdk-6u45-linux-x64-rpm.bin && \
    alternatives --install /usr/bin/java java /usr/java/jdk1.6.0_45/jre/bin/java 20000 && \
    alternatives --install /usr/bin/javac javac /usr/java/jdk1.6.0_45/bin/javac 20000 && \
    alternatives --install /usr/bin/jar jar /usr/java/jdk1.6.0_45/bin/jar 20000
    
ENV JAVA_HOME /usr/java/jdk1.6.0_45

WORKDIR /usr/local

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

COPY --from=installer /software/apache-tomcat-${TOMCAT_VERSION} .

RUN set -x && \
    rm bin/tomcat-native.tar.gz && \
    \
# sh removes env vars it doesn't support (ones with periods)
# https://github.com/docker-library/tomcat/issues/77
    find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' + && \
    \
# fix permissions (especially for running as non-root)
# https://github.com/docker-library/tomcat/issues/35
    chmod -R +rX . && \
    chmod 777 logs temp work

EXPOSE 8080
CMD ["catalina.sh", "run"]
