#!/bin/bash
NODES=${NODES:-}
MUNIN_USER=${MUNIN_USER:-user}
MUNIN_PASSWORD=${MUNIN_PASSWORD:-password}

htpasswd -b -c /etc/munin/htpasswd.users "$MUNIN_USER" "$MUNIN_PASSWORD"

# generate node list
for NODE in $NODES
do
    NAME=`echo $NODE | cut -d ":" -f1`
    HOST=`echo $NODE | cut -d ":" -f2`
    cat << EOF >> /etc/munin/munin.conf
[$NAME]
    address $HOST
    use_node_name yes

EOF
done

# placeholder html to prevent permission error
if [ ! -e /var/cache/munin/www/index.html ]; then
cat << EOF > /var/cache/munin/www/index.html
<html>
<head>
  <title>Munin</title>
</head>
<body>
Munin has not run yet.  Please try again in a few moments.
</body>
</html>
EOF
chown munin:munin /var/cache/munin/www/index.html
chmod g+w /var/cache/munin/www/index.html
fi

# start rsyslogd
/usr/sbin/rsyslogd
# start cron
/usr/sbin/cron
# start local munin-node
/usr/sbin/munin-node
echo "Using the following munin nodes:"
echo $NODES
# start apache
/usr/sbin/nginx
# show logs
echo "Tailing /var/log/syslog..."
tail -F /var/log/syslog /var/log/munin/munin-update.log
