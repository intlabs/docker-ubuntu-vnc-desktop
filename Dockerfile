FROM ubuntu:14.04
MAINTAINER Doro Wu <fcwu.tw@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root

# setup our Ubuntu sources (ADD breaks caching)
RUN echo "deb http://tw.archive.ubuntu.com/ubuntu/ trusty main\n\
deb http://tw.archive.ubuntu.com/ubuntu/ trusty multiverse\n\
deb http://tw.archive.ubuntu.com/ubuntu/ trusty universe\n\
deb http://tw.archive.ubuntu.com/ubuntu/ trusty restricted\n\
deb http://ppa.launchpad.net/chris-lea/node.js/ubuntu trusty main\n\
"> /etc/apt/sources.list

# no Upstart or DBus
# https://github.com/dotcloud/docker/issues/1724#issuecomment-26294856
RUN apt-mark hold initscripts udev plymouth mountall
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

# Installing fuse filesystem is not possible in docker without elevated priviliges
# but we can fake installling it to allow packages we need to install for GNOME
RUN apt-get update
RUN apt-get install libfuse2 -y && \
cd /tmp ; apt-get download fuse && \
cd /tmp ; dpkg-deb -x fuse_* . && \
cd /tmp ; dpkg-deb -e fuse_* && \
cd /tmp ; rm fuse_*.deb && \
cd /tmp ; echo -en '#!/bin/bash\nexit 0\n' > DEBIAN/postinst && \
cd /tmp ; dpkg-deb -b . /fuse.deb && \
cd /tmp ; dpkg -i /fuse.deb



RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends supervisor \
        openssh-server pwgen sudo vim-tiny \
        net-tools \
        gnome-core x11vnc xvfb \
        gtk2-engines-murrine ttf-ubuntu-font-family \
        nodejs \
        libreoffice firefox \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

ADD noVNC /noVNC/

EXPOSE 22
ADD startup.sh /
ADD supervisord.conf /
EXPOSE 6080
EXPOSE 5900
WORKDIR /
ENTRYPOINT ["/startup.sh"]
