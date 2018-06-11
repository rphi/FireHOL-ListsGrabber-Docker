FROM debian:stretch-slim

RUN apt-get update && apt-get install -y zlib1g-dev gcc make git autoconf autogen automake pkg-config curl ipset iproute kmod systemd screen inetutils-traceroute iputils-ping unzip cron

# download iprange and firehol from github
RUN cd /tmp && git clone https://github.com/firehol/iprange.git && git clone https://github.com/firehol/firehol.git

# install iprange
RUN cd /tmp/iprange && ./autogen.sh && ./configure --prefix=/usr CFLAGS="-march=native -O3" --disable-man && make && make install

# install firehol
RUN cd /tmp/firehol && ./autogen.sh && ./configure --prefix=/usr --sysconfdir=/etc --disable-man --disable-doc && make && make install

# store ipsets in /ipsets and don't update kernel
RUN echo 'IPSETS_APPLY=0' >> /etc/firehol/update-ipsets.conf
RUN mkdir /usr/var && mkdir /usr/var/run && mkdir /ipsets

# run initial pull of lists and enable all sources
RUN update-ipsets --enable-all
RUN ls /etc/firehol/ipsets

# make ipsets available to host
VOLUME /ipsets

# setup cron (running at odd interval to reduce load spikes on list servers)
COPY ./update-ipsets-cron.sh /usr/var/update-ipsets-cron.sh
COPY ./start.sh /usr/var/start.sh
RUN chmod +x /usr/var/update-ipsets-cron.sh /usr/var/start.sh  && echo "*/27 * * * * root bash /usr/var/update-ipsets-cron.sh" >> /etc/crontab

# start cron in foreground (so docker can monitor it)
ENTRYPOINT /usr/var/start.sh