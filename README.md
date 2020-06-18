# Docker image for munin server

## Configuration

All the configuration is done through the environment.

### HTTP Credentials 

These are the credentials used to authenticate the HTTP dashboard; both take a space-delimited list

* `MUNIN_USERS`
* `MUNIN_PASSWORDS`

### SMTP info for alerts

Email credentials used to send emails (like alerts)

* `SMTP_HOST`
* `SMTP_PORT`
* `SMTP_USERNAME`
* `SMTP_PASSWORD`
* `SMTP_USE_TLS`
* `SMTP_ALWAYS_SEND`
* `SMTP_MESSAGE`

### Alert target

Email addressed used for the alerts, require SMTP credentials.

* `ALERT_RECIPIENT`
* `ALERT_SENDER`

### List of the nodes to check

The port is always optional, default is 4949

* `NODES` format: `name1:ip1[:port1] name2:ip2[:port2] …`
* `SNMP_NODES` format: `name1:ip1[:port1]` …
* `SSH_NODES` format: `name1:ip1[:port1]` …

## Port

Container is listening on the port 8080

## Volumes

For a bit of persistency

* /var/log/munin   -> logs
* /var/lib/munin   -> db
* /var/run/munin   -> lock and pid files
* /var/cache/munin -> file deserved by HTTP

## How to use the image

```
docker build -t munin-server .

# docker build --network=host -t munin-server .

docker run -d \
  -p 8080:8080 \
  -v /var/log/munin:/var/log/munin \
  -v /var/lib/munin:/var/lib/munin \
  -v /var/run/munin:/var/run/munin \
  -v /var/cache/munin:/var/cache/munin \
  -e MUNIN_USERS='http-user another-user' \
  -e MUNIN_PASSWORDS='secret-password other-users-password' \
  -e SMTP_HOST=smtp.example.com \
  -e SMTP_PORT=587 \
  -e SMTP_USERNAME=smtp-username \
  -e SMTP_PASSWORD=smtp-password \
  -e SMTP_USE_TLS=false \
  -e SMTP_ALWAYS_SEND=true \
  -e SMTP_MESSAGE='[${var:group};${var:host}] -> ${var:graph_title} -> warnings: ${loop<,>:wfields  ${var:label}=${var:value}} / criticals: ${loop<,>:cfields  ${var:label}=${var:value}}' \
  -e ALERT_RECIPIENT=monitoring@example.com \
  -e ALERT_SENDER=alerts@example.com \
  -e NODES="server1:10.0.0.1 server2:10.0.0.2" \
  -e SNMP_NODES="router1:10.0.0.254:9999" \
  munin-server
```

A simple `run-image` example is provided which assumes `munin.conf` contains environment variable values, or copied from a local Munin server instance.

You can now reach your munin-server on port 8080 of your host. It will display at the first run:

```
Munin has not run yet. Please try again in a few moments.
```

Every 5 minutes munin-server will interrogate its nodes and build the graphs and store the data.
That's only after the first data fetching operation that the first graphs will appear.
