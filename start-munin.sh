#!/bin/bash
NODES=${NODES:-}
MUNIN_USER=${MUNIN_USER:-user}
MUNIN_PASSWORD=${MUNIN_PASSWORD:-password}

if [ -n "${SMTP_USERNAME}" -a -n "${SMTP_PASSWORD}" -a -n "${SMTP_HOST}" -a -n "${SMTP_PORT}" ] ; then
  cat > /var/lib/munin/.mailrc <<EOF
  set smtp-use-starttls
  set ssl-verify=ignore
  set smtp=smtp://${SMTP_HOST}:${SMTP_PORT}
  set smtp-auth=login
  set smtp-auth-user=${SMTP_USERNAME}
  set smtp-auth-password=${SMTP_PASSWORD}
EOF
fi

grep -q 'contact.mail' /etc/munin/munin.conf; rc=$?
if  [ $rc -ne 0 -a -n "${ALERT_RECIPIENT}" -a -n "${ALERT_SENDER}" ] ; then
  echo "Setup alert email from ${ALERT_SENDER} to ${ALERT_RECIPIENT}"
  echo 'contact.mail.command mail -r '${ALERT_SENDER}' -s "[${var:group};${var:host}] -> ${var:graph_title} -> warnings: ${loop<,>:wfields  ${var:label}=${var:value}} / criticals: ${loop<,>:cfields  ${var:label}=${var:value}}"' ${ALERT_RECIPIENT} >> /etc/munin/munin.conf
fi

[ -e /etc/munin/htpasswd.users ] || htpasswd -b -c /etc/munin/htpasswd.users "$MUNIN_USER" "$MUNIN_PASSWORD"

# generate node list
for NODE in $NODES
do
  NAME=`echo $NODE | cut -d ":" -f1`
  HOST=`echo $NODE | cut -d ":" -f2`
  if ! grep -q $HOST /etc/munin/munin.conf ; then
    cat << EOF >> /etc/munin/munin.conf
[$NAME]
    address $HOST
    use_node_name yes

EOF
    fi
done

[ -d /var/cache/munin/www ] || mkdir /var/cache/munin/www
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
chown munin:munin -R /var/cache/munin/www
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
tail -F /var/log/syslog /var/log/munin/munin-update.log & pid=$!

sleep 1

trap "kill $pid $(cat /var/run/munin/munin-node.pid) $(cat /var/run/nginx.pid) $(cat /var/run/crond.pid) $(cat /var/run/rsyslogd.pid)" TERM QUIT INT

wait
