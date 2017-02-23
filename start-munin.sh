#!/bin/bash
NODES=${NODES:-}
SNMP_NODES=${SNMP_NODES:-}
MUNIN_USERS=${MUNIN_USERS:-user}
MUNIN_PASSWORDS=${MUNIN_PASSWORDS:-password}
MAIL_CONF_PATH='/var/lib/munin/.mailrc'
SMTP_USE_TLS=${SMTP_USE_TLS:-false}
SMTP_ALWAYS_SEND=${SMTP_ALWAYS_SEND:-true}
SMTP_MESSAGE_DEFAULT='[${var:group};${var:host}] -> ${var:graph_title} -> warnings: ${loop<,>:wfields  ${var:label}=${var:value}} / criticals: ${loop<,>:cfields  ${var:label}=${var:value}}'
SMTP_MESSAGE="${SMTP_MESSAGE:-$SMTP_MESSAGE_DEFAULT}"

truncate -s 0 "${MAIL_CONF_PATH}"

# set volume ownerships
chown -R munin:munin /var/log/munin
chown -R munin:munin /var/lib/munin
chown -R munin:munin /var/run/munin
chown -R munin:munin /var/cache/munin

if [ "${SMTP_USE_TLS}" = true ] ; then
  cat >> "${MAIL_CONF_PATH}" <<EOF
set smtp-use-starttls
set ssl-verify=ignore
EOF
fi

if [ -n "${SMTP_HOST}" -a -n "${SMTP_PORT}" ] ; then
  cat >> "${MAIL_CONF_PATH}" <<EOF
set smtp=smtp://${SMTP_HOST}:${SMTP_PORT}
EOF
fi

if [ -n "${SMTP_USERNAME}" -a -n "${SMTP_PASSWORD}" ] ; then
  cat >> "${MAIL_CONF_PATH}" <<EOF
set smtp-auth=login
set smtp-auth-user=${SMTP_USERNAME}
set smtp-auth-password=${SMTP_PASSWORD}
EOF
fi

grep -q 'contact.mail' /etc/munin/munin.conf; rc=$?
if  [ $rc -ne 0 -a -n "${ALERT_RECIPIENT}" -a -n "${ALERT_SENDER}" ] ; then
  echo "Setup alert email from ${ALERT_SENDER} to ${ALERT_RECIPIENT}"
  echo "contact.mail.command mail -r ${ALERT_SENDER} -s '${SMTP_MESSAGE}' ${ALERT_RECIPIENT}" >> /etc/munin/munin.conf
  if [ "${SMTP_ALWAYS_SEND}" = true ] ; then
    echo 'contact.mail.always_send warning critical' >> /etc/munin/munin.conf
  fi
fi

# generate the Munin auth username/password file
if [ ! -f /etc/munin/htpasswd.users ]; then
  uc = 0
  IFS=' ' read -ra ARR_USERS <<< "$MUNIN_USERS"
  IFS=' ' read -ra ARR_PASSWORDS <<< "$MUNIN_PASSWORDS"
  for u in "${ARR_USERS[@]}"; do
    printf "${u}:`openssl passwd -apr1 ${ARR_PASSWORDS[uc]}`\n" >> /etc/munin/htpasswd.users
    (( uc++ ))
  done
fi

# generate node list
for NODE in $NODES
do
  NAME=`echo $NODE | cut -d ":" -f1`
  HOST=`echo $NODE | cut -d ":" -f2`
  PORT=`echo $NODE | cut -d ":" -f3`
  if [ ${#PORT} -eq 0 ]; then
      PORT=4949
  fi
  if ! grep -q $HOST /etc/munin/munin.conf ; then
    cat << EOF >> /etc/munin/munin.conf
[$NAME]
    address $HOST
    use_node_name yes
    port $PORT

EOF
    fi
done

# generate node list
for NODE in $SNMP_NODES
do
  NAME=`echo $NODE | cut -d ":" -f1`
  HOST=`echo $NODE | cut -d ":" -f2`
  PORT=`echo $NODE | cut -d ":" -f3`
  if [ ${#PORT} -eq 0 ]; then
      PORT=4949
  fi
  if ! grep -q $HOST /etc/munin/munin.conf ; then
    cat << EOF >> /etc/munin/munin.conf
[$NAME]
    address $HOST
    use_node_name no
    port $PORT

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
# start spawn-cgi to enable CGI interface with munin (dynamix graph generation)
spawn-fcgi -s /var/run/munin/fcgi-graph.sock -U munin -u munin -g munin /usr/lib/munin/cgi/munin-cgi-graph
# start nginx
/usr/sbin/nginx
# show logs
echo "Tailing /var/log/syslog..."
tail -F /var/log/syslog /var/log/munin/munin-update.log & pid=$!
echo "tail -F running in $pid"

sleep 1

trap "echo 'stopping processes' ; kill $pid $(cat /var/run/munin/munin-node.pid) $(cat /var/run/nginx.pid) $(cat /var/run/crond.pid) $(cat /var/run/rsyslogd.pid)" SIGTERM SIGINT

echo "Waiting for signal SIGINT/SIGTERM"
wait
