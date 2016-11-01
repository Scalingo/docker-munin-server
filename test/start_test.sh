#!/bin/bash

if [ -z "$1" ] ; then
  echo "usage: $0 <id of docker image>"
  exit 1
fi

basedir="$( cd -P "$( dirname "$0" )" && pwd )/munin"

docker run -it \
  -p 8080:8080 \
  -v $basedir/log:/var/log/munin \
  -v $basedir/lib:/var/lib/munin \
  -v $basedir/run:/run/munin \
  -v $basedir/cache:/var/cache/munin \
  -e MUNIN_USER=user \
  -e MUNIN_PASSWORD=secret \
  -e NODES="172.17.0.1:$(hostname)" \
  $1
