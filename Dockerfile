FROM ubuntu:20.04

MAINTAINER Leo Unbekandt <leo@scalingo.com>

RUN adduser --system --home /var/lib/munin --shell /bin/false --uid 1103 --group munin

RUN apt-get update -qq && RUNLEVEL=1 DEBIAN_FRONTEND=noninteractive \
    apt-get install -y -qq cron munin munin-node nginx wget bsd-mailx patch spawn-fcgi libcgi-fast-perl telnet
RUN rm /etc/nginx/sites-enabled/default && mkdir -p /var/cache/munin/www && chown munin:munin /var/cache/munin/www && mkdir -p /var/run/munin && chown -R munin:munin /var/run/munin

VOLUME /var/lib/munin
VOLUME /var/log/munin

ADD ./munin.conf /etc/munin/munin.conf
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./nginx-munin /etc/nginx/sites-enabled/munin
ADD ./start-munin.sh /munin
ADD ./munin-graph-logging.patch /usr/share/munin
ADD ./munin-update-logging.patch /usr/share/munin

RUN cd /usr/share/munin && patch munin-graph < munin-graph-logging.patch && patch munin-update < munin-update-logging.patch

EXPOSE 8080
CMD ["bash", "/munin"]
